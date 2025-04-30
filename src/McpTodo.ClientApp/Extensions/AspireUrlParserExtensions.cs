namespace McpTodo.ClientApp.Extensions;

public static class AspireUrlParserExtensions
{
    public static Uri Resolve(this Uri uri, IConfiguration config)
    {
        var absoluteUrl = uri.ToString();
        if (absoluteUrl.StartsWith("http://") || absoluteUrl.StartsWith("https://"))
        {
            return uri;
        }
        if (absoluteUrl.StartsWith("https+http://"))
        {
            var appname = absoluteUrl.Substring("https+http://".Length).Split('/')[0];
            var https = config[$"services:{appname}:https:0"]!;
            var http = config[$"services:{appname}:http:0"]!;

            return string.IsNullOrWhiteSpace(https) == true
                   ? new Uri(http)
                   : new Uri(https);
        }

        throw new InvalidOperationException($"Invalid URL format: {absoluteUrl}. Expected format: 'https+http://appname' or 'http://appname'.");
    }
}
