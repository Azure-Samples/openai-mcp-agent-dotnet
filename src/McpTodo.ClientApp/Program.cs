using System.ClientModel;
using System.Data.Common;

using McpTodo.ClientApp.Components;

using OpenAI;
using OpenAI.Responses;

#pragma warning disable OPENAI001

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration;

builder.Services.AddRazorComponents()
                .AddInteractiveServerComponents();

builder.Services.AddScoped<OpenAIResponseClient>(sp =>
{
    string? connectionString = config.GetConnectionString("openai");
    OpenAIClientOptions? openAIOptions;
    ApiKeyCredential? credential;
    if (!string.IsNullOrWhiteSpace(connectionString))
    {
        var parts = new DbConnectionStringBuilder() { ConnectionString = connectionString };
        string? endpoint = parts.TryGetValue("Endpoint", out var ep) == true && ep is string epStr
                        ? (epStr.TrimEnd('/').EndsWith(".openai.azure.com") == true
                              ? $"{epStr.TrimEnd('/')}/openai/v1/"
                              : epStr.TrimEnd('/')
                          )
                        : throw new InvalidOperationException("Missing Endpoint in connection string.");

        openAIOptions = new OpenAIClientOptions { Endpoint = new Uri(endpoint) };

        credential = parts.TryGetValue("Key", out var key) == true && key is string keyStr && string.IsNullOrWhiteSpace(keyStr) == false
                   ? new(keyStr.Trim())
                   : throw new InvalidOperationException("Missing Key in connection string.");
    }
    else
    {
        string? endpoint = config["OpenAI:Endpoint"]?.TrimEnd('/');
        openAIOptions = string.IsNullOrWhiteSpace(endpoint) == true
            ? null
            : (endpoint.TrimEnd('/').EndsWith(".openai.azure.com") == true
                  ? new() { Endpoint = new Uri($"{endpoint}/openai/v1/") }
                  : throw new InvalidOperationException("Invalid Azure OpenAI endpoint.")
              );

        string? apiKey = string.IsNullOrWhiteSpace(config["OpenAI:ApiKey"]) == false
                       ? config["OpenAI:ApiKey"]!.Trim()
                       : throw new InvalidOperationException("Missing API key.");
        credential = new(apiKey);
    }

    string? model = config["OpenAI:DeploymentName"]?.Trim() ?? "gpt-5-mini";
    OpenAIResponseClient responseClient = openAIOptions == null
        ? new(model, credential)
        : new(model, credential, openAIOptions);

    return responseClient;
});

builder.Services.AddSingleton<ResponseCreationOptions>(sp =>
{
    string? serverUri = config["McpServers:TodoList"]?.TrimEnd('/') ?? throw new InvalidOperationException("Missing MCP server URL.");
    string? authorizationToken = config["McpServers:JWT:Token"]?.Trim() ?? throw new InvalidOperationException("Missing MCP server JWT token.");

    ResponseCreationOptions options = new()
    {
        Tools = {
            ResponseTool.CreateMcpTool(
                serverLabel: "TodoList",
                serverUri: new Uri($"{serverUri}/mcp"),
                authorizationToken: authorizationToken,
                toolCallApprovalPolicy: new McpToolCallApprovalPolicy(GlobalMcpToolCallApprovalPolicy.NeverRequireApproval)
            )
        }
    };

    return options;
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseAntiforgery();

app.UseStaticFiles();
app.MapRazorComponents<App>()
   .AddInteractiveServerRenderMode();

app.Run();
