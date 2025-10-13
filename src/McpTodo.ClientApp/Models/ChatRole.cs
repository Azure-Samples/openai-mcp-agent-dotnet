using System.Text.Json.Serialization;

namespace McpTodo.ClientApp.Models;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum ChatRole
{
    [JsonStringEnumMemberName("system")]
    System,

    [JsonStringEnumMemberName("user")]
    User,

    [JsonStringEnumMemberName("assistant")]
    Assistant
}