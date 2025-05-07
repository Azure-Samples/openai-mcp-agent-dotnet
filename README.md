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

1. Add Azure OpenAI API Key.

    ```bash
    dotnet user-secrets --project ./src/McpTodo.ClientApp set ConnectionStrings:openai "Endpoint={{AZURE_OPENAI_ENDPOINT}};Key={{AZURE_OPENAI_API_KEY}}"
    ```

   > **NOTE**: You can add GitHub PAT in the same format above to use GitHub Models like `Endpoint=https://models.inference.ai.azure.com;Key={{GITHUB_PAT}}`.

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
        | sed 's/ConnectionStrings:openai/ConnectionStrings__openai/' > .env
    ```

    ```bash
    # PowerShell
    (dotnet user-secrets list --project src/McpTodo.ClientApp).Replace("ConnectionStrings:openai", "ConnectionStrings__openai") `
        | Out-File ".env" -Force
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

1. Navigate to `https://localhost:8080` and enter prompts like:

    ```text
    Give me list of to do.
    Set "meeting at 1pm".
    Give me list of to do.
    Mark #1 as completed.
    Delete #1 from the to-do list.
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

   > **NOTE**: During the deployment, you will be asked to enter the Azure Subscription, location and OpenAI connection string.
   > The connection string should be in the format of `Endpoint={{AZURE_OPENAI_ENDPOINT}};Key={{AZURE_OPENAI_API_KEY}}`.

1. In the terminal, get the client app URL deployed. It might look like:

    ```bash
    https://mcptodo-clientapp.{{some-random-string}}.{{location}}.azurecontainerapps.io/
    ```

1. Navigate to the client app URL, log-in to the app and enter prompts like:

    ```text
    Give me list of to do.
    Set "meeting at 1pm".
    Give me list of to do.
    Mark #1 as completed.
    Delete #1 from the to-do list.
    ```

## TO-DO

- [x] Add [Azure AI Project](https://github.com/Azure/azure-sdk-for-net/tree/main/sdk/cloudmachine) integration.
- [ ] Add [Azure API Management](https://learn.microsoft.com/azure/api-management/credentials-overview) integration.
- [x] Remove GitHub Models integration.
- [ ] Add devcontainer settings.

## Resources

TBD
