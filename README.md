[![MseeP.ai Security Assessment Badge](https://mseep.net/pr/azure-samples-openai-mcp-agent-dotnet-badge.png)](https://mseep.ai/app/azure-samples-openai-mcp-agent-dotnet)

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

- To run this app, you should have an [Azure AI Foundry](https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry) instance.
- If you use Azure AI Foundry, make sure you have the [GPT-5-mini models](https://learn.microsoft.com/azure/ai-foundry/how-to/deploy-models-openai) deployed.
- As a default, the deployed model name is `gpt-5-mini`.

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

   > **NOTE**: You'll be asked to enter an environment name, which will be the name of your Azure Resource Group. For example, the environment name might be `openai-mcp-agent`.

### Run on Azure

1. Check that you have the necessary permissions:
   - Your Azure account must have the `Microsoft.Authorization/roleAssignments/write` permission, such as [Role Based Access Control Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#role-based-access-control-administrator), [User Access Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#user-access-administrator), or [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#owner) at the subscription level.
   - Your Azure account must also have the `Microsoft.Resources/deployments/write` permission at the subscription level.

1. Login to Azure.

    ```bash
    azd auth login
    ```

1. Deploy apps to Azure. It will automatically find the [MCP server app](https://github.com/Azure-Samples/mcp-container-ts) and deploy it at the same time.

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
   > 1. By default, the agent uses `gpt-5-mini`. You can change it to something else by setting:
   >
   >    ```bash
   >    azd env set GPT_MODEL_NAME <azure-openai-model-name>
   >    ```
   >
   > 1. By default, the agent uses the [keyless approach](https://learn.microsoft.com/azure/developer/ai/how-to/switching-endpoints?tabs=azure-openai&pivots=dotnet#microsoft-entra-authentication-1) for Azure OpenAI authentication. You can change it to use [Azure OpenAI API key](https://learn.microsoft.com/azure/developer/ai/how-to/switching-endpoints?tabs=azure-openai&pivots=dotnet#api-key-authentication) by setting:
   >
   >    ```bash
   >    azd env set AOAI_USE_API_KEY true
   >    ```
   >
   > 1. By default, the agent is production mode. You can change it to the development mode to either `Both` or `Client` that shows more detailed logs by setting:
   >
   >    ```bash
   >    azd env set ENABLE_DEVELOPMENT_MODE Both
   >    ```
   >
   > 1. By default, the MCP server app is production mode. You can change it to the development mode to either `Both` or `Server` that shows more detailed logs by setting:
   >
   >    ```bash
   >    azd env set ENABLE_DEVELOPMENT_MODE Both
   >    ```
   >
   > 1. During the deployment,
   >    - You will be asked to enter the Azure Subscription and two locations - one for Azure AI Foundry and the other for the rest of resources.

2. In the terminal, get the client app URL deployed. It might look like:

    ```bash
    https://mcptodo-clientapp.{{some-random-string}}.{{location}}.azurecontainerapps.io/
    ```

3. Navigate to the client app URL, log-in to the app and enter prompts like:

    ```text
    Give me list of to do.
    Set "meeting at 1pm".
    Give me list of to do.
    Mark #1 as completed.
    Delete #1 from the to-do list.
    ```

   > **NOTE**: You might not be asked to login, if you've set the `USE_LOGIN` value to `false`.

4. Clean up all the resources deployed.

    ```bash
    azd down --force --prune
    ```

## Resources

- [OpenAI SDK - .NET](https://github.com/openai/openai-dotnet)
- [OpenAI MCP samples](https://platform.openai.com/docs/guides/tools-connectors-mcp)
- [Azure OpenAI - Next-generation API](https://learn.microsoft.com/azure/ai-foundry/openai/api-version-lifecycle#next-generation-api)
- [How to switch between OpenAI and Azure OpenAI endpoints](https://learn.microsoft.com/azure/developer/ai/how-to/switching-endpoints?pivots=dotnet)
- [.NET AI Template](https://devblogs.microsoft.com/dotnet/announcing-dotnet-ai-template-preview2/)
- [MCP .NET samples](https://github.com/microsoft/mcp-dotnet-samples)
- [MCP Todo app in TypeScript](https://github.com/Azure-Samples/mcp-container-ts)
