#pragma warning disable OPENAI001

using McpTodo.ClientApp.Models;

using Microsoft.AspNetCore.Components;

using OpenAI.Responses;

namespace McpTodo.ClientApp.Components.Pages.Chat;

public partial class ChatSuggestions : ComponentBase
{
    [Inject]
    public OpenAIResponseClient ResponseClient { get; set; } = null!;

    [Inject]
    public ResponseCreationOptions ResponseOptions { get; set; } = null!;

    private static string Prompt = @"
        Suggest up to 3 follow-up questions that I could ask you to help me complete my task.
        Each suggestion must be a complete sentence, maximum 6 words.
        Each suggestion must be phrased as something that I (the user) would ask you (the assistant) in response to your previous message,
        for example 'How do I do that?' or 'Explain ...'.
        Every suggestion must be relevant to to-do list management and the context of our conversation so far.
        If there are no suggestions, reply with an empty list.
    ";

    private string[]? suggestions;
    private CancellationTokenSource? cancellation;

    [Parameter]
    public EventCallback<ChatMessage> OnSelected { get; set; }

    public void Clear()
    {
        suggestions = null;
        cancellation?.Cancel();
    }

    public void Update(IReadOnlyList<ChatMessage> messages)
    {
        // Runs in the background and handles its own cancellation/errors
        _ = UpdateSuggestionsAsync(messages);
    }

    private async Task UpdateSuggestionsAsync(IReadOnlyList<ChatMessage> messages)
    {
        cancellation?.Cancel();
        cancellation = new CancellationTokenSource();

        try
        {
            List<ResponseItem> responseItems = [];
            foreach (var message in messages)
            {
                if (message.Role == ChatRole.System)
                {
                    responseItems.Add(ResponseItem.CreateSystemMessageItem(message.Text));
                }
                else if (message.Role == ChatRole.User)
                {
                    responseItems.Add(ResponseItem.CreateUserMessageItem(message.Text));
                }
                else if (message.Role == ChatRole.Assistant)
                {
                    responseItems.Add(ResponseItem.CreateAssistantMessageItem(message.Text));
                }
                else
                {
                    throw new InvalidOperationException($"Unknown role: {message.Role}");
                }
            }

            var reducedMessages = ReduceMessages(responseItems);
            var response = await ResponseClient.CreateResponseAsync([
                .. reducedMessages,
                ResponseItem.CreateUserMessageItem(Prompt)
            ], cancellationToken: cancellation.Token);

            suggestions = [.. response.Value.GetOutputText()
                                      .Split([ '\n', '\r' ], StringSplitOptions.RemoveEmptyEntries)
                                      .Select(s => s.Trim())
                                      .Where(s => !string.IsNullOrWhiteSpace(s))];

            StateHasChanged();
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            await DispatchExceptionAsync(ex);
        }
    }

    private async Task AddSuggestionAsync(string text)
    {
        await OnSelected.InvokeAsync(new(ChatRole.User, text));
    }

    private IEnumerable<ResponseItem> ReduceMessages(IReadOnlyList<ResponseItem> responseItems)
    {
        // Get any leading system messages, plus up to 5 user/assistant messages
        // This should be enough context to generate suggestions without unnecessarily resending entire conversations when long
        var systemMessages = responseItems.TakeWhile(m => m is MessageResponseItem item && item.Role == MessageRole.System);
        var otherMessages = responseItems.Where((m, index) => m is MessageResponseItem item && (item.Role == MessageRole.User || item.Role == MessageRole.Assistant))
                                         .Where(m => (MessageResponseItem)m! is { Content.Count: > 0 }).TakeLast(5);
        return systemMessages.Concat(otherMessages);
    }
}
