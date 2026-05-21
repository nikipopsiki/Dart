  import 'dart:io';
  import 'package:path/path.dart';
  import 'package:sqflite/sqflite.dart';
  import 'package:path_provider/path_provider.dart';
  import '../models/user_model.dart';
  import '../models/post_model.dart';
  import '../models/chat_model.dart';

  class DatabaseHelper {
    static final DatabaseHelper _instance = DatabaseHelper._internal();
    factory DatabaseHelper() => _instance;
    DatabaseHelper._internal();

    static Database? _database;

    Future<Database> get database async {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    }

    Future<Database> _initDatabase() async {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'app_database.db');
      
      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    Future<void> _onCreate(Database db, int version) async {
      await db.execute('''
        CREATE TABLE users(
          id TEXT PRIMARY KEY,
          first_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          phone_number TEXT UNIQUE NOT NULL,
          email TEXT,
          password TEXT NOT NULL,
          avatar_path TEXT,
          registration_date TEXT NOT NULL,
          is_phone_hidden INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE posts(
          id TEXT PRIMARY KEY,
          author_id TEXT NOT NULL,
          text TEXT,
          image_path TEXT,
          video_path TEXT,
          likes INTEGER DEFAULT 0,
          comments INTEGER DEFAULT 0,
          reposts INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (author_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE likes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          post_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE(post_id, user_id),
          FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE comments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          post_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          text TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE chats(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          avatar_path TEXT,
          last_message TEXT,
          last_message_time TEXT,
          is_online INTEGER DEFAULT 0,
          unread_count INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE chat_participants(
          chat_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          joined_at TEXT NOT NULL,
          PRIMARY KEY (chat_id, user_id),
          FOREIGN KEY (chat_id) REFERENCES chats (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chat_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          text TEXT NOT NULL,
          is_read INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (chat_id) REFERENCES chats (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE friends(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          friend_id TEXT NOT NULL,
          status TEXT NOT NULL, -- 'pending', 'accepted', 'blocked'
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(user_id, friend_id),
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_friends_user_id ON friends(user_id)');
      await db.execute('CREATE INDEX idx_friends_friend_id ON friends(friend_id)');
      await db.execute('CREATE INDEX idx_friends_status ON friends(status)');
      await db.execute('CREATE INDEX idx_users_name ON users(first_name, last_name)');
      await db.execute('CREATE INDEX idx_posts_created ON posts(created_at)');
      await db.execute('CREATE INDEX idx_messages_chat ON messages(chat_id, created_at)');
      await _insertSampleData(db);
    }

    Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE friends(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            friend_id TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(user_id, friend_id),
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
        
        await db.execute('CREATE INDEX idx_friends_user_id ON friends(user_id)');
        await db.execute('CREATE INDEX idx_friends_friend_id ON friends(friend_id)');
        await db.execute('CREATE INDEX idx_friends_status ON friends(status)');
        await db.execute('CREATE INDEX idx_users_name ON users(first_name, last_name)');
      }
    }

    Future<void> _insertSampleData(Database db) async {
      await db.insert('users', {
        'id': 'user1',
        'first_name': 'Анна',
        'last_name': 'Смирнова',
        'phone_number': '+79161234567',
        'email': 'anna@example.com',
        'password': 'password123', 
        'avatar_path': 'https://randomuser.me/api/portraits/women/1.jpg',
        'registration_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'is_phone_hidden': 0,
      });

      await db.insert('users', {
        'id': 'user2',
        'first_name': 'Иван',
        'last_name': 'Петров',
        'phone_number': '+79162345678',
        'email': 'ivan@example.com',
        'password': 'password123',
        'avatar_path': 'https://randomuser.me/api/portraits/men/2.jpg',
        'registration_date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'is_phone_hidden': 0,
      });

      await db.insert('users', {
        'id': 'user3',
        'first_name': 'Елена',
        'last_name': 'Козлова',
        'phone_number': '+79163456789',
        'email': 'elena@example.com',
        'password': 'password123',
        'avatar_path': 'https://randomuser.me/api/portraits/women/3.jpg',
        'registration_date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'is_phone_hidden': 0,
      });

      
      await db.insert('posts', {
        'id': 'post1',
        'author_id': 'user1',
        'text': 'Сегодня был прекрасный день! Гуляла в парке, кормила уток. Погода просто замечательная 🦆☀️',
        'image_path': 'https://images.unsplash.com/photo-1502083896352-259ab9e342d7?w=600',
        'likes': 15,
        'comments': 3,
        'reposts': 1,
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      });

      await db.insert('posts', {
        'id': 'post2',
        'author_id': 'user2',
        'text': 'Посмотрел новый фильм, очень рекомендую! Отличный сюжет и игра актеров. Кто уже видел? 🎬',
        'image_path': 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=600',
        'likes': 42,
        'comments': 8,
        'reposts': 3,
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });

      await db.insert('posts', {
        'id': 'post3',
        'author_id': 'user3',
        'text': 'Мой новый питомец! Встречайте Барсика 🐱',
        'image_path': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600',
        'likes': 89,
        'comments': 12,
        'reposts': 5,
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      });
      await db.insert('chats', {
        'id': 'chat1',
        'name': 'Анна Смирнова',
        'avatar_path': 'https://randomuser.me/api/portraits/women/1.jpg',
        'last_message': 'Привет! Как дела?',
        'last_message_time': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'is_online': 1,
        'unread_count': 2,
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      });

      await db.insert('chat_participants', {
        'chat_id': 'chat1',
        'user_id': 'user1',
        'joined_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      });

      await db.insert('chat_participants', {
        'chat_id': 'chat1',
        'user_id': 'user2',
        'joined_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      });
      await db.insert('messages', {
        'chat_id': 'chat1',
        'user_id': 'user1',
        'text': 'Привет!',
        'is_read': 1,
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      });

      await db.insert('messages', {
        'chat_id': 'chat1',
        'user_id': 'user2',
        'text': 'Здравствуйте!',
        'is_read': 1,
        'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 50)).toIso8601String(),
      });

      await db.insert('messages', {
        'chat_id': 'chat1',
        'user_id': 'user1',
        'text': 'Как дела?',
        'is_read': 0,
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      });
      await db.insert('chats', {
        'id': 'chat2',
        'name': 'Елена Козлова',
        'avatar_path': 'https://randomuser.me/api/portraits/women/3.jpg',
        'last_message': 'Спасибо за помощь!',
        'last_message_time': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'is_online': 0,
        'unread_count': 0,
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      });

      await db.insert('chat_participants', {
        'chat_id': 'chat2',
        'user_id': 'user1',
        'joined_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      });

      await db.insert('chat_participants', {
        'chat_id': 'chat2',
        'user_id': 'user3',
        'joined_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      });

      final now = DateTime.now().toIso8601String();
      await db.insert('friends', {
        'user_id': 'user1',
        'friend_id': 'user2',
        'status': 'accepted',
        'created_at': now,
        'updated_at': now,
      });
      
      await db.insert('friends', {
        'user_id': 'user2',
        'friend_id': 'user1',
        'status': 'accepted',
        'created_at': now,
        'updated_at': now,
      });
    }

    Future<User?> getUserByPhone(String phoneNumber) async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'phone_number = ?',
        whereArgs: [phoneNumber],
      );
      
      if (maps.isEmpty) return null;
      return User.fromMap(maps.first);
    }

    Future<User?> getUserById(String id) async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      return User.fromMap(maps.first);
    }

    Future<List<User>> getAllUsers() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('users');
      return maps.map((map) => User.fromMap(map)).toList();
    }

    Future<void> insertUser(User user) async {
      final db = await database;
      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    Future<void> updateUser(User user) async {
      final db = await database;
      await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    }

    Future<List<User>> searchUsers({
      String? query,
      String? userId,
    }) async {
      final db = await database;
      
      String sql = 'SELECT * FROM users WHERE 1=1';
      List<dynamic> args = [];
      
      if (query != null && query.isNotEmpty) {
        sql += ''' AND (
          id LIKE ? OR 
          phone_number LIKE ? OR 
          first_name LIKE ? OR 
          last_name LIKE ? OR
          (first_name || ' ' || last_name) LIKE ?
        )''';
        
        final searchPattern = '%$query%';
        args.addAll([searchPattern, searchPattern, searchPattern, searchPattern, searchPattern]);
      }
      
      if (userId != null) {
        sql += ' AND id != ?';
        args.add(userId);
      }
      
      sql += ' ORDER BY first_name, last_name LIMIT 50';
      
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
      return maps.map((map) => User.fromMap(map)).toList();
    }


  Future<void> sendFriendRequest(String userId, String friendId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final existing = await db.query(
      'friends',
      where: '(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)',
      whereArgs: [userId, friendId, friendId, userId],
    );
    
    if (existing.isEmpty) {
      await db.insert('friends', {
        'user_id': userId,
        'friend_id': friendId,
        'status': 'pending',
        'created_at': now,
        'updated_at': now,
      });
    } else {
      final status = existing.first['status'];
      if (status == 'rejected' || status == 'blocked') {

        await db.update(
          'friends',
          {
            'status': 'pending',
            'updated_at': now,
          },
          where: 'user_id = ? AND friend_id = ?',
          whereArgs: [userId, friendId],
        );
      }
    }
  }

    Future<void> acceptFriendRequest(String userId, String friendId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.transaction((txn) async {

      await txn.update(
        'friends',
        {
          'status': 'accepted',
          'updated_at': now,
        },
        where: 'user_id = ? AND friend_id = ? AND status = "pending"',
        whereArgs: [friendId, userId],
      );
      
     
      final existingReverse = await txn.query(
        'friends',
        where: 'user_id = ? AND friend_id = ?',
        whereArgs: [userId, friendId],
      );
      if (existingReverse.isEmpty) {
        await txn.insert('friends', {
          'user_id': userId,
          'friend_id': friendId,
          'status': 'accepted',
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await txn.update(
          'friends',
          {
            'status': 'accepted',
            'updated_at': now,
          },
          where: 'user_id = ? AND friend_id = ?',
          whereArgs: [userId, friendId],
        );
      }
    });
  }

    Future<void> rejectFriendRequest(String userId, String friendId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(  
      'friends',
      {
        'status': 'rejected',
        'updated_at': now,
      },
      where: 'user_id = ? AND friend_id = ? AND status = "pending"',
      whereArgs: [friendId, userId],
    );
  }

    Future<void> removeFriend(String userId, String friendId) async {
    final db = await database;
    await db.delete(
      'friends',
      where: '(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)',
      whereArgs: [userId, friendId, friendId, userId],
    );
  }

    Future<List<User>> getFriends(String userId) async {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT u.* FROM users u
        INNER JOIN friends f ON u.id = f.friend_id
        WHERE f.user_id = ? AND f.status = 'accepted'
        ORDER BY u.first_name, u.last_name
      ''', [userId]);
      
      return maps.map((map) => User.fromMap(map)).toList();
    }

    Future<List<User>> getFriendRequests(String userId) async {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT u.* FROM users u
        INNER JOIN friends f ON u.id = f.user_id
        WHERE f.friend_id = ? AND f.status = 'pending'
        ORDER BY f.created_at DESC
      ''', [userId]);
      
      return maps.map((map) => User.fromMap(map)).toList();
    }

    Future<String?> getFriendStatus(String userId, String otherUserId) async {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'friends',
        where: 'user_id = ? AND friend_id = ?',
        whereArgs: [userId, otherUserId],
      );
      
      if (maps.isEmpty) return null;
      return maps.first['status'] as String;
    }

    Future<List<User>> searchFriends(String userId, {String? query}) async {
      final db = await database;
      
      String sql = '''
        SELECT u.* FROM users u
        INNER JOIN friends f ON u.id = f.friend_id
        WHERE f.user_id = ? AND f.status = 'accepted'
      ''';
      
      List<dynamic> args = [userId];
      
      if (query != null && query.isNotEmpty) {
        sql += ''' AND (
          u.first_name LIKE ? OR 
          u.last_name LIKE ? OR
          (u.first_name || ' ' || u.last_name) LIKE ?
        )''';
        
        final searchPattern = '%$query%';
        args.addAll([searchPattern, searchPattern, searchPattern]);
      }
      
      sql += ' ORDER BY u.first_name, u.last_name';
      
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
      return maps.map((map) => User.fromMap(map)).toList();
    }
    Future<void> insertPost(Post post) async {
      final db = await database;
      
      await db.insert(
        'posts',
        {
          'id': post.id,
          'author_id': post.authorId,
          'text': post.text,
          'image_path': post.imageUrl,
          'video_path': post.videoUrl,
          'likes': post.likes,
          'comments': post.comments,
          'reposts': post.reposts,
          'created_at': post.time.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    Future<List<Post>> getAllPosts() async {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          p.*,
          u.first_name as author_first_name,
          u.last_name as author_last_name,
          u.avatar_path as author_avatar
        FROM posts p
        INNER JOIN users u ON p.author_id = u.id
        ORDER BY p.created_at DESC
      ''');
      
      return maps.map((map) {
        return Post(
          id: map['id'],
          authorId: map['author_id'],
          authorName: '${map['author_first_name']} ${map['author_last_name']}',
          authorAvatar: map['author_avatar'] ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
          time: DateTime.parse(map['created_at']),
          text: map['text'],
          imageUrl: map['image_path'],
          videoUrl: map['video_path'],
          likes: map['likes'] ?? 0,
          comments: map['comments'] ?? 0,
          reposts: map['reposts'] ?? 0,
        );
      }).toList();
    }

    Future<List<Post>> getUserPosts(String userId) async {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          p.*,
          u.first_name as author_first_name,
          u.last_name as author_last_name,
          u.avatar_path as author_avatar
        FROM posts p
        INNER JOIN users u ON p.author_id = u.id
        WHERE p.author_id = ?
        ORDER BY p.created_at DESC
      ''', [userId]);
      
      return maps.map((map) {
        return Post(
          id: map['id'],
          authorId: map['author_id'],
          authorName: '${map['author_first_name']} ${map['author_last_name']}',
          authorAvatar: map['author_avatar'] ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
          time: DateTime.parse(map['created_at']),
          text: map['text'],
          imageUrl: map['image_path'],
          videoUrl: map['video_path'],
          likes: map['likes'] ?? 0,
          comments: map['comments'] ?? 0,
          reposts: map['reposts'] ?? 0,
        );
      }).toList();
    }

    Future<void> deletePost(String postId) async {
      final db = await database;
      await db.delete(
        'posts',
        where: 'id = ?',
        whereArgs: [postId],
      );
    }

    Future<void> toggleLike(String postId, String userId) async {
      final db = await database;
      
      final List<Map<String, dynamic>> existingLike = await db.query(
        'likes',
        where: 'post_id = ? AND user_id = ?',
        whereArgs: [postId, userId],
      );
      
      if (existingLike.isEmpty) {
        await db.insert('likes', {
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        await db.execute(
          'UPDATE posts SET likes = likes + 1 WHERE id = ?',
          [postId],
        );
      } else {
        await db.delete(
          'likes',
          where: 'post_id = ? AND user_id = ?',
          whereArgs: [postId, userId],
        );
        
        await db.execute(
          'UPDATE posts SET likes = likes - 1 WHERE id = ?',
          [postId],
        );
      }
    }

    Future<bool> isPostLiked(String postId, String userId) async {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'likes',
        where: 'post_id = ? AND user_id = ?',
        whereArgs: [postId, userId],
      );
      return result.isNotEmpty;
    }

    Future<void> addComment(String postId, String userId, String text) async {
      final db = await database;
      
      await db.insert('comments', {
        'post_id': postId,
        'user_id': userId,
        'text': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.execute(
        'UPDATE posts SET comments = comments + 1 WHERE id = ?',
        [postId],
      );
    }

    Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
      final db = await database;
      
      return await db.rawQuery('''
        SELECT 
          c.*,
          u.first_name,
          u.last_name,
          u.avatar_path
        FROM comments c
        INNER JOIN users u ON c.user_id = u.id
        WHERE c.post_id = ?
        ORDER BY c.created_at DESC
      ''', [postId]);
    }
    Future<List<Chat>> getUserChats(String userId) async {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT c.* FROM chats c
        INNER JOIN chat_participants cp ON c.id = cp.chat_id
        WHERE cp.user_id = ?
        ORDER BY c.last_message_time DESC
      ''', [userId]);
      
      return List.generate(maps.length, (i) {
        return Chat.fromMap(maps[i]);
      });
    }

    Future<List<Message>> getChatMessages(String chatId) async {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [chatId],
        orderBy: 'created_at ASC',
      );
      
      return List.generate(maps.length, (i) {
        return Message.fromMap(maps[i]);
      });
    }

    Future<void> sendMessage(Message message) async {
      final db = await database;
      await db.insert('messages', message.toMap());
      
      await db.update(
        'chats',
        {
          'last_message': message.text,
          'last_message_time': message.createdAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [message.chatId],
      );
    }

    Future<Chat> createChatWithFriend(String currentUserId, String friendId) async {
      final db = await database;
      
      final existingChat = await db.rawQuery('''
        SELECT c.* FROM chats c
        INNER JOIN chat_participants cp1 ON c.id = cp1.chat_id
        INNER JOIN chat_participants cp2 ON c.id = cp2.chat_id
        WHERE cp1.user_id = ? AND cp2.user_id = ?
        GROUP BY c.id
        HAVING COUNT(DISTINCT cp1.user_id) = 2
      ''', [currentUserId, friendId]);
      
      if (existingChat.isNotEmpty) {
        return Chat.fromMap(existingChat.first);
      }
      final friend = await getUserById(friendId);
      final chatId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now().toIso8601String();
      
      await db.insert('chats', {
        'id': chatId,
        'name': friend!.fullName,
        'avatar_path': friend.avatarPath,
        'created_at': now,
      });
      
      await db.insert('chat_participants', {
        'chat_id': chatId,
        'user_id': currentUserId,
        'joined_at': now,
      });
      
      await db.insert('chat_participants', {
        'chat_id': chatId,
        'user_id': friendId,
        'joined_at': now,
      });
      
      return Chat(
        id: chatId,
        name: friend.fullName,
        avatarPath: friend.avatarPath,
        createdAt: DateTime.parse(now),
        messages: [],
      );
    }

    Future<void> markMessagesAsRead(String chatId, String userId) async {
      final db = await database;
      
      await db.update(
        'messages',
        {'is_read': 1},
        where: 'chat_id = ? AND user_id != ? AND is_read = 0',
        whereArgs: [chatId, userId],
      );
    }
  }