using System.ClientModel;

using Azure.AI.OpenAI;

using McpTodo.ClientApp;
using McpTodo.ClientApp.Components;

using Microsoft.Extensions.AI;

using OpenAI;
using OpenAI.Responses;

#pragma warning disable OPENAI001

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddRazorComponents()
                .AddInteractiveServerComponents();

builder.Services.AddScoped<OpenAIResponseClient>(sp =>
{
    IConfiguration config = sp.GetRequiredService<IConfiguration>();
    string connectionstring = config.GetConnectionString("openai") ?? throw new InvalidOperationException("Missing connection string: openai.");
    string endpoint = connectionstring.Split(';').FirstOrDefault(x => x.StartsWith("Endpoint=", StringComparison.InvariantCultureIgnoreCase))?.Split('=')[1]
                      ?? throw new InvalidOperationException("Missing endpoint.");
    string apiKey = connectionstring.Split(';').FirstOrDefault(x => x.StartsWith("Key=", StringComparison.InvariantCultureIgnoreCase))?.Split('=')[1]
                    ?? throw new InvalidOperationException("Missing API key.");

    ApiKeyCredential credential = new(apiKey);
    OpenAIClientOptions openAIOptions = new()
    {
        Endpoint = new Uri(endpoint),
    };

    OpenAIClient openAIClient = Constants.GitHubModelEndpoints.Contains(endpoint.TrimEnd('/'))
                              ? new OpenAIClient(credential, openAIOptions)
                              : new AzureOpenAIClient(new Uri(endpoint), credential);

    OpenAIResponseClient responseClient = openAIClient.GetOpenAIResponseClient(config["OpenAI:DeploymentName"]);

    return responseClient;
});

builder.Services.AddSingleton<ResponseCreationOptions>(sp =>
{
    IConfiguration config = sp.GetRequiredService<IConfiguration>();

    ResponseCreationOptions options = new()
    {
        Tools = { ResponseTool.CreateMcpTool(
            serverLabel: "TodoList",
            serverUri: new Uri($"{config["McpServers:TodoList"]!.TrimEnd('/')}/mcp"),
            headers: new Dictionary<string, string>
            {
                { "Authorization", $"Bearer {config["McpServers:JWT:Token"]!}" }
            },
            toolCallApprovalPolicy: new McpToolCallApprovalPolicy(GlobalMcpToolCallApprovalPolicy.NeverRequireApproval)
        ) }
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
}

app.UseHttpsRedirection();
app.UseAntiforgery();

app.UseStaticFiles();
app.MapRazorComponents<App>()
   .AddInteractiveServerRenderMode();

app.MapDefaultEndpoints();

app.Run();
