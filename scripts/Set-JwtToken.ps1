<#
Script: Set-JwtToken.ps1

Synopsis:
Generates a JWT for the MCP server app, parses .env into a hashtable, and stores the token in .NET user-secrets.

What it does:
- Detects repository root via `git rev-parse --show-toplevel`.
- Enters `src/McpTodo.ServerApp`, installs npm deps, runs `npm run generate-token` (creates/updates `.env`).
- Parses `.env` into an [ordered] hashtable `$dotenv`.
- Returns to the original directory and writes `McpServers:JWT:Token` to user-secrets.

Usage:
- pwsh .\scripts\Set-JwtToken.ps1

Outputs:
- Updates `src/McpTodo.ServerApp/.env`.
- Exposes `$dotenv` in the current session.
- Persists `McpServers:JWT:Token` in user-secrets for the default project.
#>
$REPOSITORY_ROOT = git rev-parse --show-toplevel

pushd $REPOSITORY_ROOT/src/McpTodo.ServerApp

Write-Host "Installing npm packages..."
npm install

Write-Host "Generating JWT token..."
npm run generate-token

Write-Host "Storing JWT token in user-secrets..."
# Read .env into a hashtable ($dotenv)
$dotenv = [ordered]@{}

Get-Content -LiteralPath "./.env" -ErrorAction Stop | ForEach-Object {
    $line = $_.Trim()
    if (-not $line) { return }

    # Handle BOM and comments/exports
    $line = $line.TrimStart([char]0xFEFF)
    if ($line.StartsWith('#')) { return }
    if ($line.StartsWith('export ')) { $line = $line.Substring(7).Trim() }

    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { return }

    $key = $line.Substring(0, $eq).Trim()
    $value = $line.Substring($eq + 1).Trim()

    # Strip surrounding quotes
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    # Unescape common sequences
    $value = $value -replace '\\n', "`n" -replace '\\r', "`r" -replace '\\t', "`t"

    # Remove inline comment if preceded by whitespace
    $hashPos = $value.IndexOf('#')
    if ($hashPos -ge 0 -and ($hashPos -eq 0 -or $value[$hashPos - 1] -match '\s')) {
        $value = $value.Substring(0, $hashPos).TrimEnd()
    }

    $dotenv[$key] = $value
}

popd

dotnet user-secrets --project ./src/McpTodo.ClientApp set McpServers:JWT:Token "$($dotenv["JWT_TOKEN"])"
