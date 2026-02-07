class User {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? profileImageUrl;
  final String? status;
  final int? lastSeen;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.profileImageUrl,
    this.status,
    this.lastSeen,
  });

  factory User.fromMap(String id, Map<dynamic, dynamic> map) {
    return User(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      status: map['status'],
      lastSeen: map['lastSeen'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'status': status,
      'lastSeen': lastSeen,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? bio,
    String? profileImageUrl,
    String? status,
    int? lastSeen,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
