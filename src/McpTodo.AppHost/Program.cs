var builder = DistributedApplication.CreateBuilder(args);

var config = builder.Configuration;

var mcpserver = builder.AddNpmApp("mcpserver", "../McpTodo.ServerApp")
                       .WithHttpEndpoint(port: 3000, env: "PORT")
                       .PublishAsDockerFile();

builder.AddProject<Projects.McpTodo_ClientApp>("mcpclient")
       .WithReference(mcpserver)
       .WithEnvironment("GitHubModels__Token", config["GitHubModels:Token"]!)
       .WaitFor(mcpserver);

builder.Build().Run();
