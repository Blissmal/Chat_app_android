import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user.dart' as app_user;
import 'chat_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final currentUserId = authService.currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Elegant Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<app_user.User>>(
              stream: databaseService.getAllUsersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.where((u) => u.id != currentUserId).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isOnline = user.status == 'online';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _handleUserClick(context, databaseService, currentUserId!, user),
                        contentPadding: const EdgeInsets.all(12),
                        leading: _buildUserAvatar(user, context),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user.bio ?? 'Hey there! I am using this chat.', maxLines: 1),
                        trailing: isOnline
                            ? const Icon(Icons.bolt, color: Colors.amber, size: 20)
                            : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(app_user.User user, BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
        image: user.profileImageUrl != null
            ? DecorationImage(image: NetworkImage(user.profileImageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: user.profileImageUrl == null
          ? Center(child: Text(user.name[0], style: const TextStyle(fontWeight: FontWeight.bold)))
          : null,
    );
  }

  Future<void> _handleUserClick(BuildContext context, DatabaseService db, String currentId, app_user.User user) async {
    // Show a modern progress overlay
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

    final chatId = await db.createChat([currentId, user.id]);

    if (context.mounted) {
      Navigator.pop(context); // Close loader
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUser: user)));
    }
  }
}
