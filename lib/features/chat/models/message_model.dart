// lib/features/chat/models/message_model.dart

enum MessageType { text, audio }

class MessageModel {
  final String id;
  final String senderId;
  final String? text;
  final String? audioUrl;
  final MessageType type;
  final int timestamp; // Unix ms
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    this.text,
    this.audioUrl,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(String id, Map<dynamic, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      text: data['text'],
      audioUrl: data['audioUrl'],
      type: (data['type'] == 'audio') ? MessageType.audio : MessageType.text,
      timestamp: (data['timestamp'] ?? 0).toInt(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'audioUrl': audioUrl,
    'type': type.name,
    'timestamp': timestamp,
    'isRead': isRead,
  };
}
