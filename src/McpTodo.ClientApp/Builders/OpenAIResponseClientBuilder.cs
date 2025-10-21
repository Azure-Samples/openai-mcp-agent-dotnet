#pragma warning disable OPENAI001

using System.ClientModel;
using System.Data.Common;

using Azure.AI.OpenAI;
using Azure.Core;
using Azure.Identity;

using OpenAI;
using OpenAI.Responses;

namespace McpTodo.ClientApp.Builders;

public class OpenAIResponseClientBuilder(IConfiguration config, bool development)
{
    private readonly IConfiguration _config = config ?? throw new ArgumentNullException(nameof(config));
    private readonly bool _development = development;

    public OpenAIResponseClient Build()
    {
        var connectionString = this._config.GetConnectionString("openai");
        var endpoint = this._config["OpenAI:Endpoint"]?.Trim();
        var apiKey = this._config["OpenAI:ApiKey"]?.Trim();
        var model = this._config["OpenAI:DeploymentName"]?.Trim() ?? "gpt-5-mini";

        if (string.IsNullOrWhiteSpace(connectionString) == false)
        {
            return BuildFromConnectionString(connectionString, model);
        }

        if (string.IsNullOrWhiteSpace(endpoint) == false)
        {
            return BuildFromEndpoint(endpoint, apiKey, model);
        }

        if (string.IsNullOrWhiteSpace(apiKey) == false)
        {
            return new OpenAIResponseClient(model, new ApiKeyCredential(apiKey!));
        }

        throw new InvalidOperationException("Missing configuration. Provide either a connection string named 'openai' or OpenAI:Endpoint and OpenAI:ApiKey configuration.");
    }

    private static (Uri endpointUri, bool isAzure) VerifyEndpoint(string? endpoint)
    {
        var trimmed = endpoint?.Trim().TrimEnd('/') ?? throw new ArgumentNullException(nameof(endpoint));
        var isAzure = trimmed.EndsWith(".openai.azure.com", StringComparison.InvariantCultureIgnoreCase);
        var uri = isAzure ? new Uri($"{trimmed}/openai/v1/") : new Uri(trimmed);

        return (uri, isAzure);
    }

    private OpenAIResponseClient BuildFromConnectionString(string? connectionString, string? model)
    {
        ArgumentNullException.ThrowIfNullOrWhiteSpace(connectionString);
        ArgumentNullException.ThrowIfNullOrWhiteSpace(model);

        var parts = new DbConnectionStringBuilder() { ConnectionString = connectionString };
        if (parts.TryGetValue("Endpoint", out var endpointVal) == false || endpointVal is not string endpoint || string.IsNullOrWhiteSpace(endpoint) == true)
        {
            throw new InvalidOperationException("Missing Endpoint in connection string.");
        }

        var (uri, isAzure) = VerifyEndpoint(endpoint);

        if (parts.TryGetValue("Key", out var keyVal) == false || keyVal is not string key || string.IsNullOrWhiteSpace(key) == true)
        {
            return isAzure == true
                ? new AzureOpenAIClient(uri, GetTokenCredential(this._config, this._development)).GetOpenAIResponseClient(model)
                : throw new InvalidOperationException("Missing Key in connection string.");
        }

        var credential = new ApiKeyCredential(key.Trim());
        var options = new OpenAIClientOptions { Endpoint = uri };

        return new OpenAIResponseClient(model, credential, options);
    }

    private OpenAIResponseClient BuildFromEndpoint(string? endpoint, string? apiKey, string? model)
    {
        ArgumentNullException.ThrowIfNullOrWhiteSpace(endpoint);
        ArgumentNullException.ThrowIfNullOrWhiteSpace(model);

        var (uri, isAzure) = VerifyEndpoint(endpoint);

        if (string.IsNullOrWhiteSpace(apiKey) == true)
        {
            return isAzure == true
                ? new AzureOpenAIClient(uri, GetTokenCredential(this._config, this._development)).GetOpenAIResponseClient(model)
                : throw new InvalidOperationException("Missing API key in configuration.");
        }

        var credential = new ApiKeyCredential(apiKey);
        var options = new OpenAIClientOptions { Endpoint = uri };

        return new OpenAIResponseClient(model, credential, options);
    }

    private static TokenCredential GetTokenCredential(IConfiguration config, bool development)
    {
        return development == true
            ? new DefaultAzureCredential()
            : new ManagedIdentityCredential(ManagedIdentityId.FromUserAssignedClientId(config["AZURE_CLIENT_ID"]));
    }
}
