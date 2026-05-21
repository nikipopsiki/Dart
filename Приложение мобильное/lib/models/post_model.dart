class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final DateTime time;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  int likes;
  int comments;
  int reposts;
  bool isLiked;
  List<String> likedBy;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.time,
    this.text,
    this.imageUrl,
    this.videoUrl,
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.isLiked = false,
    this.likedBy = const [],
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      authorId: map['author_id'],
      authorName: map['author_name'] ?? 'Пользователь',
      authorAvatar: map['author_avatar'] ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      time: DateTime.parse(map['created_at']),
      text: map['text'],
      imageUrl: map['image_path'],
      videoUrl: map['video_path'],
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      reposts: map['reposts'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'text': text,
      'image_path': imageUrl,
      'video_path': videoUrl,
      'likes': likes,
      'comments': comments,
      'reposts': reposts,
      'created_at': time.toIso8601String(),
    };
  }

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    DateTime? time,
    String? text,
    String? imageUrl,
    String? videoUrl,
    int? likes,
    int? comments,
    int? reposts,
    bool? isLiked,
    List<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      time: time ?? this.time,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      reposts: reposts ?? this.reposts,
      isLiked: isLiked ?? this.isLiked,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}