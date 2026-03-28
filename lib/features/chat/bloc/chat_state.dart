// lib/features/chat/bloc/chat_state.dart

import '../models/message_model.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState {
  final ChatStatus status;
  final List<MessageModel> messages;
  final String? error;
  final bool isSending;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.error,
    this.isSending = false,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<MessageModel>? messages,
    String? error,
    bool? isSending,
  }) => ChatState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    error: error ?? this.error,
    isSending: isSending ?? this.isSending,
  );
}
