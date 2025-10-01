#!/usr/bin/env bash

#
# Script: set-jwttoken.sh
#
# Synopsis:
# Generates a JWT for the MCP server app, parses .env, and stores the token in .NET user-secrets.
#
# What it does:
# - Detects the repository root via `git rev-parse --show-toplevel`.
# - Enters src/McpTodo.ServerApp, installs npm deps, runs `npm run generate-token` (creates/updates .env).
# - Parses .env into an associative array and extracts JWT_TOKEN.
# - Writes McpServers:JWT:Token to user-secrets for the ClientApp project.
#
# Usage:
#   bash ./scripts/set-jwttoken.sh

set -euo pipefail

REPOSITORY_ROOT="$(git rev-parse --show-toplevel)"
SERVER_DIR="$REPOSITORY_ROOT/src/McpTodo.ServerApp"
CLIENT_DIR="$REPOSITORY_ROOT/src/McpTodo.ClientApp"

echo "Working dir: $SERVER_DIR"
pushd "$SERVER_DIR" >/dev/null

echo "Installing npm packages..."
npm install

echo "Generating JWT token..."
npm run generate-token -- --admin

if [[ ! -f .env ]]; then
	echo ".env not found after token generation" >&2
	popd >/dev/null
	exit 1
fi

declare -A dotenv

# trim helpers
_ltrim() {
	local s="$1"; s="${s#${s%%[!$'\t\r\n ']*}}"; printf '%s' "$s";
}
_rtrim() {
	local s="$1"; s="${s%${s##*[!$'\t\r\n ']}}"; printf '%s' "$s";
}
_trim() { _rtrim "$(_ltrim "$1")"; }

while IFS= read -r line || [[ -n "$line" ]]; do
	line="$(_trim "$line")"
	[[ -z "$line" ]] && continue

	# strip BOM
	line="${line#$'\xEF\xBB\xBF'}"

	# skip comments
	[[ "$line" == \#* ]] && continue

	# handle export prefix
	if [[ "$line" == export\ * ]]; then
		line="${line#export }"
		line="$(_trim "$line")"
	fi

	# split at first '='
	if [[ "$line" != *"="* ]]; then
		continue
	fi
	key="${line%%=*}"; key="$(_trim "$key")"
	value="${line#*=}"; value="$(_trim "$value")"
	[[ -z "$key" ]] && continue

	# strip surrounding quotes if both ends match
	if [[ ( "$value" == "\""*"\"" ) || ( "$value" == "'"*"'" ) ]]; then
		value="${value:1:${#value}-2}"
	fi

	# remove inline comment if preceded by whitespace
	if [[ "$value" == \#* ]]; then
		value=""
	elif [[ "$value" =~ [[:space:]]\# ]]; then
		value="${value%%#*}"
		value="$(_rtrim "$value")"
	fi

	# unescape common sequences
	value="${value//\\n/$'\n'}"
	value="${value//\\r/$'\r'}"
	value="${value//\\t/$'\t'}"

	dotenv["$key"]="$value"
done < ./.env

popd >/dev/null

TOKEN="${dotenv[JWT_TOKEN]:-}"
if [[ -z "$TOKEN" ]]; then
	echo "JWT_TOKEN not found in .env" >&2
	exit 1
fi

echo "Storing JWT token in user-secrets for ClientApp..."
dotnet user-secrets --project "$CLIENT_DIR" set McpServers:JWT:Token "$TOKEN"

echo "Done."
