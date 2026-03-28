// lib/features/chat/bloc/chat_event.dart

abstract class ChatEvent {}

class ChatStarted extends ChatEvent {
  final String chatId;
  ChatStarted(this.chatId);
}

class ChatMessageSent extends ChatEvent {
  final String text;
  ChatMessageSent(this.text);
}

class ChatAudioSent extends ChatEvent {
  final String filePath;
  ChatAudioSent(this.filePath);
}

class ChatMarkedAsRead extends ChatEvent {}
