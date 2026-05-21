class Chat {
  final String id;
  final String name;
  final String? avatarPath;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isOnline;
  final int unreadCount;
  final DateTime createdAt;
  final List<Message> messages;

  Chat({
    required this.id,
    required this.name,
    this.avatarPath,
    this.lastMessage,
    this.lastMessageTime,
    this.isOnline = false,
    this.unreadCount = 0,
    required this.createdAt,
    this.messages = const [],
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      name: map['name'],
      avatarPath: map['avatar_path'],
      lastMessage: map['last_message'],
      lastMessageTime: map['last_message_time'] != null 
          ? DateTime.parse(map['last_message_time']) 
          : null,
      isOnline: map['is_online'] == 1,
      unreadCount: map['unread_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_path': avatarPath,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'is_online': isOnline ? 1 : 0,
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Chat copyWith({
    String? id,
    String? name,
    String? avatarPath,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? isOnline,
    int? unreadCount,
    DateTime? createdAt,
    List<Message>? messages,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isOnline: isOnline ?? this.isOnline,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
    );
  }
}

class Message {
  final int? id;
  final String chatId;
  final String userId;
  final String text;
  final bool isRead;
  final DateTime createdAt;
  bool isMe;

  Message({
    this.id,
    required this.chatId,
    required this.userId,
    required this.text,
    this.isRead = false,
    required this.createdAt,
    this.isMe = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      chatId: map['chat_id'],
      userId: map['user_id'],
      text: map['text'],
      isRead: map['is_read'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'user_id': userId,
      'text': text,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    String? chatId,
    String? userId,
    String? text,
    bool? isRead,
    DateTime? createdAt,
    bool? isMe,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      isMe: isMe ?? this.isMe,
    );
  }
}