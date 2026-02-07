class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final int? lastMessageTime;
  final String? lastMessageSenderId;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
  });

  factory Chat.fromMap(String id, Map<dynamic, dynamic> map) {
    return Chat(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'],
      lastMessageSenderId: map['lastMessageSenderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastMessageSenderId': lastMessageSenderId,
    };
  }
}
