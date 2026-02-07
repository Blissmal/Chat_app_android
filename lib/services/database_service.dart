import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // User operations
  Future<void> createUser(User user) async {
    try {
      await _database.ref('users/${user.id}').set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUser(String userId) async {
    try {
      final snapshot = await _database.ref('users/$userId').get();
      if (snapshot.exists) {
        return User.fromMap(
          userId,
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<User?> getUserStream(String userId) {
    return _database.ref('users/$userId').onValue.map((event) {
      if (event.snapshot.exists) {
        return User.fromMap(
          userId,
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      return null;
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _database.ref('users/$userId').update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Update user online status
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _database.ref('users/$userId').update({
        'status': status,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Set user online
  Future<void> setUserOnline(String userId) async {
    await updateUserStatus(userId, 'online');
    
    // Set up disconnect handler to mark offline when user disconnects
    _database.ref('users/$userId/status').onDisconnect().set('offline');
    _database.ref('users/$userId/lastSeen').onDisconnect().set(ServerValue.timestamp);
  }

  // Set user offline
  Future<void> setUserOffline(String userId) async {
    await updateUserStatus(userId, 'offline');
  }

  Stream<List<User>> getAllUsersStream() {
    return _database.ref('users').onValue.map((event) {
      final List<User> users = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          users.add(User.fromMap(
            key,
            Map<String, dynamic>.from(value as Map),
          ));
        });
      }
      return users;
    });
  }

  // Chat operations
  Future<String?> findExistingChat(String user1Id, String user2Id) async {
    try {
      final snapshot = await _database.ref('chats').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (var entry in data.entries) {
          final chatData = Map<String, dynamic>.from(entry.value as Map);
          final participants = List<String>.from(chatData['participants'] ?? []);
          
          if (participants.length == 2 &&
              participants.contains(user1Id) &&
              participants.contains(user2Id)) {
            return entry.key as String;
          }
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createChat(List<String> participants) async {
    try {
      // Check if chat already exists for two participants
      if (participants.length == 2) {
        final existingChatId = await findExistingChat(participants[0], participants[1]);
        if (existingChatId != null) {
          return existingChatId;
        }
      }

      final chatRef = _database.ref('chats').push();
      await chatRef.set({
        'participants': participants,
        'lastMessageTime': ServerValue.timestamp,
      });
      return chatRef.key!;
    } catch (e) {
      rethrow;
    }
  }

  Future<Chat?> getChat(String chatId) async {
    try {
      final snapshot = await _database.ref('chats/$chatId').get();
      if (snapshot.exists) {
        return Chat.fromMap(chatId, Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Chat>> getUserChatsStream(String userId) {
    return _database.ref('chats').onValue.map((event) {
      final List<Chat> chats = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final chat = Chat.fromMap(
            key,
            Map<String, dynamic>.from(value as Map),
          );
          if (chat.participants.contains(userId)) {
            chats.add(chat);
          }
        });
        chats.sort((a, b) =>
            (b.lastMessageTime ?? 0).compareTo(a.lastMessageTime ?? 0));
      }
      return chats;
    });
  }

  // Message operations
  Future<void> sendMessage(Message message) async {
    try {
      final messageRef = _database.ref('messages/${message.chatId}').push();
      await messageRef.set(message.toMap());

      // Update chat last message
      await _database.ref('chats/${message.chatId}').update({
        'lastMessage': message.text,
        'lastMessageTime': message.timestamp,
        'lastMessageSenderId': message.senderId,
      });

      // Get chat to find receiver
      final chat = await getChat(message.chatId);
      if (chat != null) {
        final receiverId = chat.participants.firstWhere(
          (id) => id != message.senderId,
          orElse: () => '',
        );

        if (receiverId.isNotEmpty) {
          // Create notification for receiver
          final sender = await getUser(message.senderId);
          await createNotification(
            userId: receiverId,
            fromUserId: message.senderId,
            type: 'message',
            message: '${sender?.name ?? 'Someone'} sent you a message',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Message>> getChatMessagesStream(String chatId) {
    return _database
        .ref('messages/$chatId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final List<Message> messages = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          messages.add(Message.fromMap(
            key,
            Map<String, dynamic>.from(value as Map),
          ));
        });
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      return messages;
    });
  }

  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _database.ref('messages/$chatId/$messageId').update({
        'isRead': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Notification operations
  Future<void> createNotification({
    required String userId,
    required String fromUserId,
    required String type,
    String? message,
  }) async {
    try {
      final notifRef = _database.ref('notifications/$userId').push();
      await notifRef.set({
        'fromUserId': fromUserId,
        'type': type,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _database
        .ref('notifications/$userId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final List<Map<String, dynamic>> notifications = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final notif = Map<String, dynamic>.from(value as Map);
          notif['id'] = key;
          notifications.add(notif);
        });
        notifications
            .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      }
      return notifications;
    });
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _database.ref('notifications/$userId/$notificationId').update({
        'isRead': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _database.ref('notifications/$userId').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        int count = 0;
        data.forEach((key, value) {
          final notif = Map<String, dynamic>.from(value as Map);
          if (notif['isRead'] == false) {
            count++;
          }
        });
        return count;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
