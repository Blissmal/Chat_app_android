import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/message.dart';
import '../models/user.dart' as app_user;

class ChatScreen extends StatefulWidget {
  final String chatId;
  final app_user.User otherUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final currentUserId = authService.currentUserId;

    if (currentUserId == null) return;

    final message = Message(
      id: '',
      chatId: widget.chatId,
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isRead: false,
    );

    _messageController.clear();

    try {
      await databaseService.sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatLastSeen(int? lastSeen) {
    if (lastSeen == null) return 'Last seen recently';
    
    final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    final now = DateTime.now();
    final difference = now.difference(lastSeenTime);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inHours < 1) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${DateFormat('MMM dd').format(lastSeenTime)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Provider.of<AuthService>(context).currentUserId;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey to make bubbles "pop"
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUser.profileImageUrl != null ? NetworkImage(widget.otherUser.profileImageUrl!) : null,
              child: widget.otherUser.profileImageUrl == null ? Text(widget.otherUser.name[0]) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.name, style: const TextStyle(fontSize: 16, color: Colors.black)),
                  Text(widget.otherUser.status == 'online' ? 'Online' : 'Offline',
                      style: TextStyle(fontSize: 12, color: widget.otherUser.status == 'online' ? Colors.green : Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(currentUserId!)),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageList(String currentUserId) {
    return StreamBuilder<List<Message>>(
      stream: Provider.of<DatabaseService>(context).getChatMessagesStream(widget.chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!;

        return ListView.builder(
          reverse: false, // Or true if you sort your DB list accordingly
          padding: const EdgeInsets.all(20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMe = msg.senderId == currentUserId;

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? Theme.of(context).primaryColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(msg.timestamp)),
                        style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: 'Type message...', border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(int timestamp1, int timestamp2) {
    final date1 = DateTime.fromMillisecondsSinceEpoch(timestamp1);
    final date2 = DateTime.fromMillisecondsSinceEpoch(timestamp2);
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }
}
