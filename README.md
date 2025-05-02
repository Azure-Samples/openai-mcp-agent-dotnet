# .NET OpenAI MCP Agent

TBD

- Clone this repo

    ```bash
    git clone https://github.com/Azure-Samples/openai-mcp-agent-dotnet.git
    ```
    

- Clone the MCP server

    ```bash
    git clone https://github.com/Azure-Samples/mcp-container-ts.git ./src/McpTodo.ServerApp
    ```
    
- Add GitHub PAT (for GitHub Model)

    ```bash
    dotnet user-secrets --project ./src/McpTodo.AppHost set GitHubModels:Token "{{GITHUB_PAT}}"
    ```

- Add Azure OpenAI API Key

    ```bash
    dotnet user-secrets --project ./src/McpTodo.AppHost set ConnectionStrings:openai "Endpoint={{AZURE_OPENAI_ENDPOINT}};Key={{AZURE_OPENAI_API_KEY}}"
    ```

- Install npm packages

    ```bash
    pushd ./src/McpTodo.ServerApp
    npm install
    popd
    ```

- Install NuGet packages

    ```bash
    dotnet restore && dotnet build
    ```

- Run the host app

    ```bash
    cd ./src/McpTodo.ServerApp
    npm start
    ```

- Run the client app

    ```bash
    dotnet watch run --project ./src/McpTodo.ClientApp
    ```

- Run both apps in containers

    ```bash
    # bash/zsh
    dotnet user-secrets list --project src/McpTodo.ClientApp | sed 's/GitHubModels:Token/GitHubModels__Token/' > .env
    docker compose up --build
    ```

    ```bash
    # PowerShell
    (dotnet user-secrets list --project src/McpTodo.ClientApp).Replace("GitHubModels:Token", "GitHubModels__Token") | Out-File ".env" -Force
    docker compose up --build
    ```
    


(short, 1-3 sentenced, description of the project)

## Features

This project framework provides the following features:

* Feature 1
* Feature 2
* ...

## Getting Started

### Prerequisites

(ideally very short, if any)

- OS
- Library version
- ...

### Installation

(ideally very short)

- npm install [package name]
- mvn install
- ...

### Quickstart
(Add steps to get up and running quickly)

1. git clone [repository clone url]
2. cd [repository name]
3. ...


## Demo

A demo app is included to show how to use the project.

To run the demo, follow these steps:

(Add steps to start up the demo)

1.
2.
3.

## Resources

(Any additional resources or related projects)

- Link to supporting information
- Link to similar sample
- ...
