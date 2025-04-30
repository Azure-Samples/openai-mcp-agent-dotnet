var builder = DistributedApplication.CreateBuilder(args);

var config = builder.Configuration;

builder.AddProject<Projects.McpTodo_ClientApp>("client")
       .WithEnvironment("GitHubModels__Token", config["GitHubModels:Token"]!);

builder.Build().Run();
