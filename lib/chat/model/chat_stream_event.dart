/// Types of events emitted during streaming
enum ChatStreamEventType {
  textDelta,
  thinkingDelta,
  toolUse,
  toolResult,
  citation,
  done,
  error,
}

/// A single event from a streaming chat response
class ChatStreamEvent {
  const ChatStreamEvent({
    required this.type,
    this.text,
    this.data,
    this.errorMessage,
  });

  final ChatStreamEventType type;
  final String? text;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  factory ChatStreamEvent.textDelta(String text) => ChatStreamEvent(
        type: ChatStreamEventType.textDelta,
        text: text,
      );

  factory ChatStreamEvent.thinkingDelta(String text) => ChatStreamEvent(
        type: ChatStreamEventType.thinkingDelta,
        text: text,
      );

  factory ChatStreamEvent.toolUse(Map<String, dynamic> data) =>
      ChatStreamEvent(
        type: ChatStreamEventType.toolUse,
        data: data,
      );

  factory ChatStreamEvent.citation(Map<String, dynamic> data) =>
      ChatStreamEvent(
        type: ChatStreamEventType.citation,
        data: data,
      );

  factory ChatStreamEvent.done() => const ChatStreamEvent(
        type: ChatStreamEventType.done,
      );

  factory ChatStreamEvent.error(String message) => ChatStreamEvent(
        type: ChatStreamEventType.error,
        errorMessage: message,
      );
}
