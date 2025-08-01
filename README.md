--- 
name: .NET OpenAI MCP Agent
description: This is an MCP agent app written in .NET, using OpenAI, with a remote MCP server written in TypeScript.
languages:
- csharp
- bicep
- azdeveloper
products:
- azure-openai
- azure-container-apps
- azure
page_type: sample
urlFragment: openai-mcp-agent-dotnet
--- 

# .NET OpenAI MCP Agent

This is an MCP agent app written in .NET, using Azure OpenAI, with a remote MCP server written in TypeScript.

## Features

This app provides features like:

- The MCP host + MCP client app is written in [.NET Blazor](https://aka.ms/blazor).
- The MCP client app connects to a to-do MCP server written in TypeScript.
- Both MCP client and server apps are running on [Azure Container Apps (ACA)](https://learn.microsoft.com/azure/container-apps/overview).
- The MCP client app is secured by the built-in auth of ACA.
- The MCP server app is only accessible from the MCP client app.

![Overall architecture diagram](./images/overall-architecture-diagram.png)

## Prerequisites

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Visual Studio Code](https://code.visualstudio.com/Download) + [C# Dev Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit)
- [node.js](https://nodejs.org/en/download) LTS
- [Docker Desktop](https://docs.docker.com/get-started/get-docker/) or [Podman Desktop](https://podman-desktop.io/downloads)
- [Azure Subscription](https://azure.microsoft.com/free)

## Getting Started

You can now use GitHub Codespaces to run this sample app (takes several minutes to open it)! 👉 [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/Azure-Samples/openai-mcp-agent-dotnet).

### Get Azure AI Foundry or GitHub Models

- To run this app, you should have either [Azure AI Foundry](https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry) instance or [GitHub Models](https://github.com/marketplace?type=models).
- If you use Azure AI Foundry, make sure you have the [GPT-4o models deployed](https://learn.microsoft.com/azure/ai-foundry/how-to/deploy-models-openai) deployed.
- As a default, the deployed model name is `gpt-4o`.

### Get AI Agent App

1. Create a directory for the app.

    ```bash
    # zsh/bash
    mkdir -p openai-mcp-agent-dotnet
    ```

    ```powershell
    # PowerShell
    New-Item -ItemType Directory -Path openai-mcp-agent-dotnet -Force
    ```

1. Initialize `azd`.

    ```bash
    cd openai-mcp-agent-dotnet
    azd init -t openai-mcp-agent-dotnet
    ```

   > **NOTE**: You'll be asked to enter an environment name, which will be the name of your Azure Resource Group.

1. Make sure that your deployed model name is `gpt-4o`. If your deployed model is different, update `src/McpTodo.ClientApp/appsettings.json`.

    ```jsonc
    {
      "OpenAI": {
        // Make sure this is the right deployment name.
        "DeploymentName": "gpt-4o"
      }
    }
    ```

### Get MCP Server App

You can choose the MCP server written either in TypeScript or .NET.

#### TypeScript MCP Server

1. clone the MCP server.

    ```bash
    git clone https://github.com/Azure-Samples/mcp-container-ts.git ./src/McpTodo.ServerApp
    ```

#### .NET MCP Server

1. Run the following command.

    ```bash
    # zsh/bash
    mv ./azure.yaml ./azure.yaml.typescript
    mv ./azure.yaml.dotnet ./azure.yaml
    ```

    ```powershell
    # PowerShell
    Rename-Item -Path ./azure.yaml -NewName ./azure.yaml.typescript
    Rename-Item -Path ./azure.yaml.dotnet -NewName ./azure.yaml
    ```

1. Run the following command.

    ```bash
    azd env set MCP_SERVER_INGRESS_PORT 8080
    ```

### Run on Azure

1. Check that you have the necessary permissions:
   - Your Azure account must have the `Microsoft.Authorization/roleAssignments/write` permission, such as [Role Based Access Control Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#role-based-access-control-administrator), [User Access Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#user-access-administrator), or [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#owner) at the subscription level.
   - Your Azure account must also have the `Microsoft.Resources/deployments/write` permission at the subscription level.

1. Login to Azure.

    ```bash
    azd auth login
    ```

1. Deploy apps to Azure.

    ```bash
    azd up
    ```

   > **NOTE**:
   >
   > 1. By default, the MCP client app is protected by the ACA built-in auth feature. You can turn off this feature before running `azd up` by setting:
   >
   >    ```bash
   >    azd env set USE_LOGIN false
   >    ```
   >
   > 1. During the deployment, you will be asked to enter the Azure Subscription, location and OpenAI connection string. The connection string should be in the format of `Endpoint={{AZURE_OPENAI_ENDPOINT}};Key={{AZURE_OPENAI_API_KEY}}`.
   >
   > 1. You can add GitHub PAT in the same format above to use GitHub Models like `Endpoint=https://models.inference.ai.azure.com;Key={{GITHUB_PAT}}`.

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

   > **NOTE**: You might not be asked to login, if you've set the `USE_LOGIN` value to `false`.

1. Clean up all the resources deployed.

    ```bash
    azd down --force --prune
    ```

### Run locally

1. Make sure you're in the `openai-mcp-agent-dotnet` directory.
1. Add Azure OpenAI API Key.

    ```bash
    dotnet user-secrets --project ./src/McpTodo.ClientApp set ConnectionStrings:openai "Endpoint={{AZURE_OPENAI_ENDPOINT}};Key={{AZURE_OPENAI_API_KEY}}"
    ```

   > **NOTE**: You can add GitHub PAT in the same format above to use GitHub Models like `Endpoint=https://models.inference.ai.azure.com;Key={{GITHUB_PAT}}`.

1. To use TypeScript version of the MCP server, install npm packages.

    ```bash
    pushd ./src/McpTodo.ServerApp
    npm install
    popd
    ```

   But to use .NET version of the MCP server, skip this step.

1. Install NuGet packages.

    ```bash
    dotnet restore && dotnet build
    ```

1. Run the MCP server app either TypeScript server or .NET one.

    ```bash
    # TypeScript MCP server
    cd ./src/McpTodo.ServerApp
    npm start
    ```

    ```bash
    # .NET MCP server
    docker run -i --rm -d -p 3000:8080 ghcr.io/microsoft/mcp-dotnet-samples/todo-list:http
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

1. Type `CTRL`+`C` to stop the agent app.
1. Stop the container, if .NET MCP server is running.

    ```bash
    docker stop $(docker ps -q --filter ancestor=ghcr.io/microsoft/mcp-dotnet-samples/todo-list:http)
    ```

### Run in local containers

1. Make sure that you're running either Docker Desktop or Podman Desktop on your local machine.
1. Make sure you're in the `openai-mcp-agent-dotnet` directory.
1. Export user secrets to `.env`.

    ```bash
    # bash/zsh
    dotnet user-secrets list --project src/McpTodo.ClientApp \
        | sed 's/ConnectionStrings:openai/ConnectionStrings__openai/' > .env
    ```

    ```bash
    # PowerShell
    (dotnet user-secrets list --project src/McpTodo.ClientApp) `
        -replace "ConnectionStrings:openai", "ConnectionStrings__openai" | Out-File ".env" -Force
    ```

1. To use TypeScript version of the MCP server, skip this step. But to use .NET version of the MCP server, run the following command.

    ```bash
    # zsh/bash
    mv ./compose.yaml ./compose.yaml.typescript
    mv ./compose.yaml.dotnet ./compose.yaml
    ```

    ```powershell
    # PowerShell
    Rename-Item -Path ./compose.yaml -NewName ./compose.yaml.typescript
    Rename-Item -Path ./compose.yaml.dotnet -NewName ./compose.yaml
    ```

1. Run both apps in containers.

    ```bash
    docker compose up --build
    ```

1. Navigate to `http://localhost:8080` and enter prompts like:

    ```text
    Give me list of to do.
    Set "meeting at 1pm".
    Give me list of to do.
    Mark #1 as completed.
    Delete #1 from the to-do list.
    ```

1. Type `CTRL`+`C` to stop all containers.
1. Delete all running containers.

    ```bash
    docker compose down
    ```

## Resources

- [.NET AI Template](https://devblogs.microsoft.com/dotnet/announcing-dotnet-ai-template-preview2/)
- [Model Context Protocol (MCP) C# SDK](https://github.com/modelcontextprotocol/csharp-sdk)
- [MCP .NET samples](https://github.com/microsoft/mcp-dotnet-samples)
- [MCP Todo app in TypeScript](https://github.com/Azure-Samples/mcp-container-ts)
