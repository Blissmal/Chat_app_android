import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/chat.dart';
import '../models/user.dart' as app_user;
import 'chat_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final currentUserId = authService.currentUserId;

    if (currentUserId == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Chat>>(
        stream: databaseService.getUserChatsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final chats = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');

              return StreamBuilder<app_user.User?>(
                stream: databaseService.getUserStream(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();

                  final otherUser = userSnapshot.data!;
                  final isOnline = otherUser.status == 'online';

                  return InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatScreen(chatId: chat.id, otherUser: otherUser),
                    )),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _buildAvatar(otherUser, isOnline, context),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      otherUser.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (chat.lastMessageTime != null)
                                      Text(
                                        _formatTimestamp(chat.lastMessageTime!),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (chat.lastMessageSenderId == currentUserId)
                                      const Icon(Icons.done_all_rounded, size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        chat.lastMessage ?? 'Start a conversation',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvatar(app_user.User user, bool isOnline, BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18), // Squircular look
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            image: user.profileImageUrl != null
                ? DecorationImage(image: NetworkImage(user.profileImageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: user.profileImageUrl == null
              ? Center(child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)))
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 14,
              width: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('No conversations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
