#pragma warning disable OPENAI001

using McpTodo.ClientApp.Extensions;
using McpTodo.ClientApp.Models;

using Microsoft.AspNetCore.Components;

using OpenAI.Responses;

namespace McpTodo.ClientApp.Components.Pages.Chat;

public partial class Chat : ComponentBase, IDisposable
{
    [Inject]
    public OpenAIResponseClient ResponseClient { get; set; } = null!;

    [Inject]
    public ResponseCreationOptions ResponseOptions { get; set; } = null!;

    private const string SystemPrompt = @"
        You are an assistant who manages to-do list items.
        If the question is not clear, ask for clarification.
        If the question is irrelevant to the to-do list one, respond like 'I only answer the to-do list related questions'.
        Use only simple markdown to format your responses.
        Answer in English.
        ";

    private readonly List<ChatMessage> messages = [];
    private readonly List<ResponseItem> responseItems = [];
    private CancellationTokenSource? currentResponseCancellation;
    private ChatMessage? currentResponseMessage;
    private ChatInput? chatInput;
    private ChatSuggestions? chatSuggestions;

    protected override async Task OnInitializedAsync()
    {
        messages.Add(new(ChatRole.System, SystemPrompt));
        responseItems.Add(ResponseItem.CreateSystemMessageItem(SystemPrompt));

        await Task.CompletedTask;
    }

    private async Task AddUserMessageAsync(ChatMessage userMessage)
    {
        CancelAnyCurrentResponse();

        // Add the user message to the conversation
        messages.Add(userMessage);
        responseItems.Add(ResponseItem.CreateUserMessageItem(userMessage.Text));

        chatSuggestions?.Clear();
        await chatInput!.FocusAsync();

        var responseText = string.Empty;
        currentResponseMessage = new ChatMessage(ChatRole.Assistant, responseText);
        currentResponseCancellation = new();

        await foreach (var update in ResponseClient.CreateResponseStreamingAsync(responseItems, ResponseOptions, currentResponseCancellation.Token))
        {
            responseText += responseItems.AddResponse(update);
            ChatMessageItem.NotifyChanged(currentResponseMessage);
        }

        // Store the final response in the conversation, and begin getting suggestions
        currentResponseMessage.Content = [ responseText ];
        messages.Add(currentResponseMessage);
        currentResponseMessage = null;
        chatSuggestions?.Update(messages);
    }

    private void CancelAnyCurrentResponse()
    {
        // If a response was cancelled while streaming, include it in the conversation so it's not lost
        if (currentResponseMessage is not null)
        {
            messages.Add(currentResponseMessage);
        }

        currentResponseCancellation?.Cancel();
        currentResponseMessage = null;
    }

    private async Task ResetConversationAsync()
    {
        CancelAnyCurrentResponse();
        messages.Clear();
        messages.Add(new(ChatRole.System, SystemPrompt));

        responseItems.Clear();
        responseItems.Add(ResponseItem.CreateSystemMessageItem(SystemPrompt));

        chatSuggestions?.Clear();
        await chatInput!.FocusAsync();
    }

    public void Dispose()
        => currentResponseCancellation?.Cancel();
}