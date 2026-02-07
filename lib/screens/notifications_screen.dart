import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final currentUserId = Provider.of<AuthService>(context).currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: databaseService.getNotificationsStream(currentUserId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isRead = n['isRead'] == true;

              return Dismissible(
                key: Key(n['id']),
                direction: DismissDirection.endToStart,
                background: _buildDismissBackground(),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : theme.primaryColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isRead ? Colors.grey.shade100 : theme.primaryColor.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    onTap: () => databaseService.markNotificationAsRead(currentUserId, n['id']),
                    contentPadding: const EdgeInsets.all(12),
                    leading: _buildNotificationIcon(n['type'], theme),
                    title: Text(
                      n['message'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_formatTimestamp(n['timestamp']), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ),
                    trailing: !isRead ? CircleAvatar(radius: 4, backgroundColor: theme.primaryColor) : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(String? type, ThemeData theme) {
    IconData icon = Icons.notifications_none_rounded;
    Color color = theme.primaryColor;
    if (type == 'message') { icon = Icons.chat_bubble_outline_rounded; color = Colors.blue; }
    if (type == 'friend_request') { icon = Icons.person_add_outlined; color = Colors.green; }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('All caught up!', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }
}
