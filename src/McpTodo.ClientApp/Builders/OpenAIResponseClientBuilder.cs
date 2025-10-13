#pragma warning disable OPENAI001

using System.ClientModel;
using System.Data.Common;

using Azure.AI.OpenAI;
using Azure.Identity;

using OpenAI;
using OpenAI.Responses;

namespace McpTodo.ClientApp.Builders;

public class OpenAIResponseClientBuilder(IConfiguration config)
{
    private readonly IConfiguration _config = config ?? throw new ArgumentNullException(nameof(config));

    public OpenAIResponseClient Build()
    {
        var connectionString = this._config.GetConnectionString("openai");
        var endpoint = this._config["OpenAI:Endpoint"]?.Trim();
        var apiKey = this._config["OpenAI:ApiKey"]?.Trim();
        var model = this._config["OpenAI:DeploymentName"]?.Trim() ?? "gpt-5-mini";

        OpenAIClientOptions? openAIOptions = default;
        ApiKeyCredential? apiKeyCredential = default;

        if (string.IsNullOrWhiteSpace(connectionString) == false)
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
            if (!string.IsNullOrWhiteSpace(endpoint))
            {
                var (uri, isAzure) = BuildEndpoint(endpoint);

                if (!string.IsNullOrWhiteSpace(apiKey))
                {
                    apiKeyCredential = new ApiKeyCredential(apiKey);
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
                apiKeyCredential = !string.IsNullOrWhiteSpace(apiKey)
                    ? new ApiKeyCredential(apiKey)
                    : throw new InvalidOperationException("Missing OpenAI configuration. Provide either a connection string named 'openai' or OpenAI:Endpoint and OpenAI:ApiKey configuration.");
            }
        }

        return apiKeyCredential is null
            ? throw new InvalidOperationException("Missing API key credential for OpenAI client.")
            : openAIOptions is null
                ? new OpenAIResponseClient(model, apiKeyCredential)
                : new OpenAIResponseClient(model, apiKeyCredential, openAIOptions);
    }

    private static (Uri endpointUri, bool isAzure) BuildEndpoint(string? endpoint)
    {
        var trimmed = endpoint?.Trim().TrimEnd('/') ?? throw new ArgumentNullException(nameof(endpoint));
        var isAzure = trimmed.EndsWith(".openai.azure.com", StringComparison.InvariantCultureIgnoreCase);
        var uri = isAzure ? new Uri($"{trimmed}/openai/v1/") : new Uri(trimmed);

        return (uri, isAzure);
    }
}
