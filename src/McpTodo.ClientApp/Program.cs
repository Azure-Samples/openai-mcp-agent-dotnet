using System.ClientModel;
using System.Data.Common;

using Azure.AI.OpenAI;
using Azure.Identity;

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

    // Helper to normalize endpoint and detect Azure OpenAI endpoints
    static (Uri endpointUri, bool isAzure) BuildEndpoint(string endpointRaw)
    {
        var trimmed = endpointRaw.Trim().TrimEnd('/');
        bool isAzure = trimmed.EndsWith(".openai.azure.com", StringComparison.OrdinalIgnoreCase);
        var uri = isAzure ? new Uri($"{trimmed}/openai/v1/") : new Uri(trimmed);
        return (uri, isAzure);
    }

    string model = config["OpenAI:DeploymentName"]?.Trim() ?? "gpt-5-mini";

    OpenAIClientOptions? openAIOptions = null;
    ApiKeyCredential? apiKeyCredential = null;

    if (!string.IsNullOrWhiteSpace(connectionString))
    {
        var parts = new DbConnectionStringBuilder() { ConnectionString = connectionString };

        if (parts.TryGetValue("Endpoint", out var ep) && ep is string epStr && string.IsNullOrWhiteSpace(epStr) == false)
        {
            var (uri, isAzure) = BuildEndpoint(epStr);

            if (parts.TryGetValue("Key", out var key) && key is string keyStr && string.IsNullOrWhiteSpace(keyStr) == false)
            {
                apiKeyCredential = new ApiKeyCredential(keyStr.Trim());
            }
            else
            {
                return isAzure
                    ? new AzureOpenAIClient(uri, new DefaultAzureCredential()).GetOpenAIResponseClient(model)
                    : throw new InvalidOperationException("Missing Key in connection string.");
            }

            openAIOptions = new OpenAIClientOptions { Endpoint = uri };
        }
        else
        {
            throw new InvalidOperationException("Missing Endpoint in connection string.");
        }
    }
    else
    {
        string? endpointCfg = config["OpenAI:Endpoint"]?.Trim();
        string? apiKeyCfg = config["OpenAI:ApiKey"]?.Trim();

        if (!string.IsNullOrWhiteSpace(endpointCfg))
        {
            var (uri, isAzure) = BuildEndpoint(endpointCfg);

            if (!string.IsNullOrWhiteSpace(apiKeyCfg))
            {
                apiKeyCredential = new ApiKeyCredential(apiKeyCfg);
            }
            else
            {
                return isAzure
                    ? new AzureOpenAIClient(uri, new DefaultAzureCredential()).GetOpenAIResponseClient(model)
                    : throw new InvalidOperationException("Missing Key in connection string.");
            }

            openAIOptions = new OpenAIClientOptions { Endpoint = uri };
        }
        else
        {
            // No endpoint configured: require API key for OpenAI API
            apiKeyCredential = !string.IsNullOrWhiteSpace(apiKeyCfg)
                ? new ApiKeyCredential(apiKeyCfg)
                : throw new InvalidOperationException("Missing OpenAI configuration. Provide either a connection string named 'openai' or OpenAI:Endpoint and OpenAI:ApiKey configuration.");
        }
    }

    return apiKeyCredential is null
        ? throw new InvalidOperationException("Missing API key credential for OpenAI client.")
        : openAIOptions is null
        ? new OpenAIResponseClient(model, apiKeyCredential)
        : new OpenAIResponseClient(model, apiKeyCredential, openAIOptions);
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
