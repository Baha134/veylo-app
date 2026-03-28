// lib/features/chat/models/chat_preview.dart

class ChatPreview {
  final String chatId;
  final String otherUid;
  final String otherNickname;
  final String? otherAvatarUrl;
  final String lastMessage;
  final int lastMessageTime;
  final bool hasUnread;

  const ChatPreview({
    required this.chatId,
    required this.otherUid,
    required this.otherNickname,
    this.otherAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.hasUnread = false,
  });
}
