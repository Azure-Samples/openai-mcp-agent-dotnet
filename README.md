# .NET OpenAI MCP Agent

This is a sample AI agent app using OpenAI models with any MCP server.

## Features

This app provides features like:

- It is an MCP host + MCP client app written in .NET Blazor.
- The MCP client app connects to a to-do MCP server written in TypeScript.
- The MCP client app connects to any MCP server through Azure API Management.

![Overall architecture diagram](./images/overall-architecture-diagram.png)

## Prerequisites

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Visual Studio Code](https://code.visualstudio.com/Download) + [C# Dev Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit)
- [node.js](https://nodejs.org/en/download) LTS
- [Docker Desktop](https://docs.docker.com/get-started/get-docker/) or [Podman Desktop](https://podman-desktop.io/downloads)

## Getting Started

### Run it locally

1. Clone this repo.

    ```bash
    git clone https://github.com/Azure-Samples/openai-mcp-agent-dotnet.git
    ```

1. Clone the MCP server.

    ```bash
    git clone https://github.com/Azure-Samples/mcp-container-ts.git ./src/McpTodo.ServerApp
    ```

1. Add GitHub PAT (for GitHub Model).

    ```bash
    dotnet user-secrets --project ./src/McpTodo.AppHost set GitHubModels:Token "{{GITHUB_PAT}}"
    ```

1. Add Azure OpenAI API Key.

    ```bash
    dotnet user-secrets --project ./src/McpTodo.AppHost set ConnectionStrings:openai "Endpoint={{AZURE_OPENAI_ENDPOINT}};Key={{AZURE_OPENAI_API_KEY}}"
    ```

1. Install npm packages.

    ```bash
    pushd ./src/McpTodo.ServerApp
    npm install
    popd
    ```

1. Install NuGet packages.

    ```bash
    dotnet restore && dotnet build
    ```

1. Run the host app.

    ```bash
    cd ./src/McpTodo.ServerApp
    npm start
    ```

1. Run the client app in another terminal.

    ```bash
    dotnet watch run --project ./src/McpTodo.ClientApp
    ```

1. Navigate to `https://localhost:7256` or `http://localhost:5011` and enter prompts like:

    ```text
    Give me list of to do.
    Set "meeting at 1pm".
    Give me list of to do.
    Mark #1 as completed.
    Delete #1 from the to-do list.
    ```

### Run it in local containers

1. Export user secrets to `.env`.

    ```bash
    # bash/zsh
    dotnet user-secrets list --project src/McpTodo.ClientApp \
        | sed 's/GitHubModels:Token/GitHubModels__Token/' \
        | sed 's/ConnectionStrings:openai/ConnectionStrings__openai/' > .env
    ```

    ```bash
    # PowerShell
    (dotnet user-secrets list --project src/McpTodo.ClientApp).Replace("GitHubModels:Token", "GitHubModels__Token").Replace("ConnectionStrings:openai", "ConnectionStrings__openai") | Out-File ".env" -Force
    ```

1. Run both apps in containers.

    ```bash
    # Docker
    docker compose up --build
    ```

    ```bash
    # Podman
    podman compose up --build
    ```

### Run it on Azure Container Apps

1. Login to Azure.

    ```bash
    azd auth login
    ```

1. Deploy apps to Azure.

    ```bash
    azd up
    ```

   During the deployment, you will be asked to enter the Azure Subscription, location and GitHub PAT.

## TO-DO

- Add [Azure AI Project](https://github.com/Azure/azure-sdk-for-net/tree/main/sdk/cloudmachine) integration.
- Remove GitHub Models integration.
- Add devcontainer settings.

## Resources

TBD
