// lib/features/chat/bloc/chat_bloc.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/chat_repository.dart';
import '../models/message_model.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repo;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  String? _chatId;

  ChatBloc({required ChatRepository chatRepository})
    : _repo = chatRepository,
      super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatAudioSent>(_onAudioSent);
    on<ChatMarkedAsRead>(_onMarkedAsRead);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    _chatId = event.chatId;
    emit(state.copyWith(status: ChatStatus.loading));

    await _messagesSub?.cancel();
    await emit.forEach<List<MessageModel>>(
      _repo.messagesStream(event.chatId),
      onData: (messages) =>
          state.copyWith(status: ChatStatus.success, messages: messages),
      onError: (_, __) => state.copyWith(status: ChatStatus.failure),
    );
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (_chatId == null || event.text.trim().isEmpty) return;
    emit(state.copyWith(isSending: true));
    try {
      await _repo.sendTextMessage(_chatId!, event.text.trim());
    } catch (_) {}
    emit(state.copyWith(isSending: false));
  }

  Future<void> _onAudioSent(
    ChatAudioSent event,
    Emitter<ChatState> emit,
  ) async {
    if (_chatId == null) return;
    emit(state.copyWith(isSending: true));
    try {
      await _repo.sendAudioMessage(_chatId!, File(event.filePath));
    } catch (_) {}
    emit(state.copyWith(isSending: false));
  }

  Future<void> _onMarkedAsRead(
    ChatMarkedAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (_chatId == null) return;
    await _repo.markAsRead(_chatId!);
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    return super.close();
  }
}
