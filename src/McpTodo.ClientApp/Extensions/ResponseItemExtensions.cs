#pragma warning disable OPENAI001

using OpenAI.Responses;

namespace McpTodo.ClientApp.Extensions;

public static class ResponseItemExtensions
{
    public static string AddResponse(this IList<ResponseItem> list, StreamingResponseUpdate update)
    {
        ArgumentNullException.ThrowIfNull(list);
        ArgumentNullException.ThrowIfNull(update);

        if (update is not StreamingResponseOutputTextDeltaUpdate)
        {
            return string.Empty;
        }

        var delta = (StreamingResponseOutputTextDeltaUpdate)update;
        list.Add(ResponseItem.CreateAssistantMessageItem(delta.Delta));

        return delta.Delta;
    }
}
