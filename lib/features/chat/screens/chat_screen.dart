// lib/features/chat/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/audio_recorder_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherNickname;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherNickname,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showMic = true;

  @override
  void initState() {
    super.initState();
    // Запрет скриншотов

    context.read<ChatBloc>()
      ..add(ChatStarted(widget.chatId))
      ..add(ChatMarkedAsRead());
    _textController.addListener(() {
      setState(() => _showMic = _textController.text.isEmpty);
    });
  }

  @override
  void dispose() {
    // Снять запрет при выходе

    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFF0EBF4),
              child: Icon(
                Icons.person_outline,
                color: Color(0xFFCBB8DC),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherNickname,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state.messages.isNotEmpty) _scrollToBottom();
              },
              builder: (context, state) {
                if (state.status == ChatStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B4FA6)),
                  );
                }
                if (state.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Начните общение 👋',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    // isMe определяем по senderId
                    return MessageBubble(
                      message: msg,
                      isMe:
                          msg.senderId ==
                          FirebaseAuth.instance.currentUser?.uid,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Сообщение...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _showMic
              ? AudioRecorderButton(
                  onAudioReady: (path) {
                    context.read<ChatBloc>().add(ChatAudioSent(path));
                  },
                )
              : GestureDetector(
                  onTap: () {
                    final text = _textController.text;
                    if (text.trim().isEmpty) return;
                    context.read<ChatBloc>().add(ChatMessageSent(text));
                    _textController.clear();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF7B4FA6),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
