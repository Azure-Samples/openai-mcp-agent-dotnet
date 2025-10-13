namespace McpTodo.ClientApp.Models;

public class ChatMessage(ChatRole role, IEnumerable<string> content)
{
    public ChatMessage(ChatRole role, string content)
        : this(role, [ content ])
    {
    }

    public ChatMessage(ChatRole role, params string[] content)
        : this(role, (IEnumerable<string>)content)
    {
    }

    public ChatRole Role { get; set; } = role;

    public IEnumerable<string> Content { get; set; } = content;

    public string Text => string.Join("", Content);
}
