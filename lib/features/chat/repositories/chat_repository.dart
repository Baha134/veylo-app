// lib/features/chat/repositories/chat_repository.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/chat_preview.dart';

class ChatRepository {
  final _db = FirebaseDatabase.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  // Стрим сообщений чата
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .ref('chats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return [];
          final map = Map<dynamic, dynamic>.from(data as Map);
          return map.entries
              .map(
                (e) => MessageModel.fromMap(
                  e.key.toString(),
                  Map<dynamic, dynamic>.from(e.value),
                ),
              )
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
  }

  // Отправить текстовое сообщение
  Future<void> sendTextMessage(String chatId, String text) async {
    final ref = _db.ref('chats/$chatId/messages').push();
    final msg = MessageModel(
      id: ref.key!,
      senderId: _currentUid,
      text: text,
      type: MessageType.text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.set(msg.toMap());
    await _updateMeta(chatId, text, msg.timestamp);
  }

  // Отправить голосовое сообщение
  Future<void> sendAudioMessage(String chatId, File audioFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
    final storageRef = _storage.ref('audio/$chatId/$fileName');
    await storageRef.putFile(audioFile);
    final audioUrl = await storageRef.getDownloadURL();

    final ref = _db.ref('chats/$chatId/messages').push();
    final msg = MessageModel(
      id: ref.key!,
      senderId: _currentUid,
      audioUrl: audioUrl,
      type: MessageType.audio,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.set(msg.toMap());
    await _updateMeta(chatId, '🎵 Голосовое сообщение', msg.timestamp);
  }

  // Обновить мета (последнее сообщение)
  Future<void> _updateMeta(String chatId, String lastMsg, int timestamp) async {
    await _db.ref('chats/$chatId/meta').update({
      'lastMessage': lastMsg,
      'lastMessageTime': timestamp,
    });
  }

  // Пометить сообщения как прочитанные
  Future<void> markAsRead(String chatId) async {
    final snap = await _db
        .ref('chats/$chatId/messages')
        .orderByChild('isRead')
        .equalTo(false)
        .get();
    if (!snap.exists) return;
    final updates = <String, dynamic>{};
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    for (final key in map.keys) {
      final msg = MessageModel.fromMap(
        key.toString(),
        Map<dynamic, dynamic>.from(map[key]),
      );
      if (msg.senderId != _currentUid) {
        updates['chats/$chatId/messages/$key/isRead'] = true;
      }
    }
    if (updates.isNotEmpty) {
      await _db.ref().update(updates);
    }
  }

  // Список диалогов текущего пользователя
  Future<List<ChatPreview>> fetchChatPreviews() async {
    final matchesSnap = await _firestore
        .collection('matches')
        .where('users', arrayContains: _currentUid)
        .orderBy('createdAt', descending: true)
        .get();

    final previews = <ChatPreview>[];

    for (final doc in matchesSnap.docs) {
      final data = doc.data();
      final users = List<String>.from(data['users']);
      final otherUid = users.firstWhere((u) => u != _currentUid);
      final chatId = data['chatId'] as String;

      // Получаем профиль собеседника
      final userDoc = await _firestore.collection('users').doc(otherUid).get();
      final nickname = userDoc.data()?['nickname'] ?? 'Аноним';
      final avatarUrl = userDoc.data()?['avatarUrl'];

      // Получаем мету чата
      final metaSnap = await _db.ref('chats/$chatId/meta').get();
      String lastMessage = 'Начните общение';
      int lastTime = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;

      if (metaSnap.exists) {
        final meta = Map<dynamic, dynamic>.from(metaSnap.value as Map);
        lastMessage = meta['lastMessage'] ?? lastMessage;
        lastTime = (meta['lastMessageTime'] ?? lastTime).toInt();
      }

      previews.add(
        ChatPreview(
          chatId: chatId,
          otherUid: otherUid,
          otherNickname: nickname,
          otherAvatarUrl: avatarUrl,
          lastMessage: lastMessage,
          lastMessageTime: lastTime,
        ),
      );
    }

    return previews;
  }
}
