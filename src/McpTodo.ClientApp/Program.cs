using McpTodo.ClientApp.Builders;
using McpTodo.ClientApp.Components;

using OpenAI.Responses;

#pragma warning disable OPENAI001

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration;

builder.Services.AddRazorComponents()
                .AddInteractiveServerComponents();

builder.Services.AddScoped<OpenAIResponseClient>(sp =>
{
    var responseClient = new OpenAIResponseClientBuilder(config)
                             .Build();
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
