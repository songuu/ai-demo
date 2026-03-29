import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:server_box/chat/model/chat_message.dart';
import 'package:server_box/chat/model/chat_provider.dart';
import 'package:server_box/chat/model/chat_stream_event.dart';
import 'package:server_box/chat/service/chat_api_service.dart';
import 'package:server_box/chat/store/chat_message_store.dart';
import 'package:server_box/chat/store/chat_conversation_store.dart';
import 'package:server_box/chat/store/chat_provider_store.dart';

class ChatStreamManager {
  ChatStreamManager._();

  /// Active streams keyed by conversationId
  static final Map<String, StreamSubscription> _activeStreams = {};

  /// Current streaming message per conversation
  static final Map<String, ValueNotifier<ChatMessage>> _streamingMessages = {};

  /// Whether a conversation is currently streaming
  static bool isStreaming(String conversationId) =>
      _activeStreams.containsKey(conversationId);

  /// Global notifier for stream state changes
  static final streamStateChanged = ValueNotifier<int>(0);

  /// Get the in-progress streaming message notifier
  static ValueNotifier<ChatMessage>? getStreamingMessage(
          String conversationId) =>
      _streamingMessages[conversationId];

  /// Start streaming a new response
  static Future<void> startStream({
    required String conversationId,
    required ChatProvider provider,
    required String modelId,
    required List<ChatMessage> history,
    double temperature = 0.7,
    int maxTokens = 4096,
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
    bool webSearch = false,
  }) async {
    // Cancel existing stream if any
    await cancelStream(conversationId);

    final requestId = '${conversationId}_${DateTime.now().millisecondsSinceEpoch}';

    // Create the assistant message placeholder
    final assistantMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: 'assistant',
      content: '',
      blocks: [],
      modelId: modelId,
      status: ChatMessageStatus.streaming,
    );

    final notifier = ValueNotifier<ChatMessage>(assistantMsg);
    _streamingMessages[conversationId] = notifier;
    streamStateChanged.value++;

    String textBuffer = '';
    String thinkingBuffer = '';
    final blocks = <Map<String, dynamic>>[];

    final eventStream = ChatApiService.sendMessage(
      provider: provider,
      modelId: modelId,
      messages: history,
      temperature: temperature,
      maxTokens: maxTokens,
      systemPrompt: systemPrompt,
      tools: tools,
      webSearch: webSearch,
      requestId: requestId,
    );

    _activeStreams[conversationId] = eventStream.listen(
      (event) {
        switch (event.type) {
          case ChatStreamEventType.textDelta:
            textBuffer += event.text ?? '';
            // Update blocks with current text
            _updateBlocks(blocks, textBuffer, thinkingBuffer);
            notifier.value = assistantMsg.copyWith(
              content: textBuffer,
              blocks: List.from(blocks),
            );
            break;

          case ChatStreamEventType.thinkingDelta:
            thinkingBuffer += event.text ?? '';
            _updateBlocks(blocks, textBuffer, thinkingBuffer);
            notifier.value = assistantMsg.copyWith(
              content: textBuffer,
              blocks: List.from(blocks),
            );
            break;

          case ChatStreamEventType.toolUse:
            if (event.data != null) {
              blocks.add({
                'type': ChatBlockType.toolUse,
                ...event.data!,
              });
              notifier.value = assistantMsg.copyWith(
                content: textBuffer,
                blocks: List.from(blocks),
              );
            }
            break;

          case ChatStreamEventType.toolResult:
            if (event.data != null) {
              blocks.add({
                'type': ChatBlockType.toolResult,
                ...event.data!,
              });
              notifier.value = assistantMsg.copyWith(
                content: textBuffer,
                blocks: List.from(blocks),
              );
            }
            break;

          case ChatStreamEventType.citation:
            if (event.data != null) {
              blocks.add({
                'type': ChatBlockType.citation,
                ...event.data!,
              });
              notifier.value = assistantMsg.copyWith(
                content: textBuffer,
                blocks: List.from(blocks),
              );
            }
            break;

          case ChatStreamEventType.done:
            _finishStream(conversationId, assistantMsg, textBuffer, blocks);
            break;

          case ChatStreamEventType.error:
            blocks.add({
              'type': ChatBlockType.error,
              'content': ChatApiService.formatError(
                event.errorMessage ?? 'Unknown error',
              ),
            });
            final errorMsg = assistantMsg.copyWith(
              content: textBuffer,
              blocks: List.from(blocks),
              status: ChatMessageStatus.error,
            );
            notifier.value = errorMsg;
            _saveAndCleanup(conversationId, errorMsg);
            break;
        }
      },
      onError: (e) {
        final errorMsg = assistantMsg.copyWith(
          content: textBuffer,
          blocks: [
            ...blocks,
            {
              'type': ChatBlockType.error,
              'content': ChatApiService.formatError(e),
            }
          ],
          status: ChatMessageStatus.error,
        );
        notifier.value = errorMsg;
        _saveAndCleanup(conversationId, errorMsg);
      },
    );
  }

  static void _updateBlocks(
    List<Map<String, dynamic>> blocks,
    String text,
    String thinking,
  ) {
    // Remove existing text/thinking blocks and rebuild
    blocks.removeWhere((b) =>
        b['type'] == ChatBlockType.text ||
        b['type'] == ChatBlockType.thinking);

    if (thinking.isNotEmpty) {
      blocks.insert(0, {
        'type': ChatBlockType.thinking,
        'content': thinking,
      });
    }
    if (text.isNotEmpty) {
      // Insert text block after thinking (if any)
      final insertIdx = thinking.isNotEmpty ? 1 : 0;
      blocks.insert(insertIdx, {
        'type': ChatBlockType.text,
        'content': text,
      });
    }
  }

  static void _finishStream(
    String conversationId,
    ChatMessage assistantMsg,
    String textBuffer,
    List<Map<String, dynamic>> blocks,
  ) {
    _updateBlocks(blocks, textBuffer, '');
    final finalMsg = assistantMsg.copyWith(
      content: textBuffer,
      blocks: List.from(blocks),
      status: ChatMessageStatus.complete,
    );
    _streamingMessages[conversationId]?.value = finalMsg;
    _saveAndCleanup(conversationId, finalMsg);
  }

  static Future<void> _saveAndCleanup(
    String conversationId,
    ChatMessage message,
  ) async {
    await ChatMessageStore.put(message);

    // Update conversation metadata
    final conv = ChatConversationStore.byId(conversationId);
    if (conv != null) {
      final preview = message.content.length > 80
          ? message.content.substring(0, 80)
          : message.content;
      await ChatConversationStore.put(conv.copyWith(
        lastMessagePreview: preview,
        messageCount: ChatMessageStore.forConversation(conversationId).length,
      ));
    }

    _activeStreams[conversationId]?.cancel();
    _activeStreams.remove(conversationId);
    _streamingMessages.remove(conversationId);
    streamStateChanged.value++;
  }

  /// Cancel a streaming response
  static Future<void> cancelStream(String conversationId) async {
    if (!_activeStreams.containsKey(conversationId)) return;

    await _activeStreams[conversationId]?.cancel();
    _activeStreams.remove(conversationId);

    final notifier = _streamingMessages[conversationId];
    if (notifier != null) {
      final msg = notifier.value.copyWith(
        status: ChatMessageStatus.cancelled,
      );
      await ChatMessageStore.put(msg);
      notifier.value = msg;
    }
    _streamingMessages.remove(conversationId);
    streamStateChanged.value++;
  }

  /// Regenerate the last assistant message
  static Future<void> regenerate(String conversationId) async {
    final messages = ChatMessageStore.forConversation(conversationId);
    if (messages.isEmpty) return;

    // Find last assistant message and remove it
    final lastAssistant =
        messages.lastWhere((m) => m.isAssistant, orElse: () => messages.last);
    await ChatMessageStore.remove(lastAssistant.id);

    // Get updated history (everything before the removed message)
    final history = ChatMessageStore.forConversation(conversationId);
    if (history.isEmpty) return;

    final conv = ChatConversationStore.byId(conversationId);
    if (conv == null || conv.providerId == null || conv.modelId == null) return;

    final provider = ChatProviderStore.byId(conv.providerId!);
    if (provider == null) return;

    await startStream(
      conversationId: conversationId,
      provider: provider,
      modelId: conv.modelId!,
      history: history,
      temperature: conv.temperature,
      maxTokens: conv.maxTokens,
      systemPrompt: conv.systemPrompt,
    );
  }
}
