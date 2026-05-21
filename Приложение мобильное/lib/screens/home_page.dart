import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../managers/post_manager.dart';
import 'user_profile_page.dart';

class HomePage extends StatefulWidget {
  final User? currentUser;

  const HomePage({super.key, this.currentUser});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<void> _loadPostsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null) {
      PostManager().setCurrentUser(widget.currentUser!.id);
    }
    _loadPostsFuture = PostManager().loadPosts();
  }

  Future<void> _toggleLike(Post post) async {
    if (widget.currentUser != null) {
      await PostManager().toggleLike(post.id, widget.currentUser!.id);
      setState(() {});
    }
  }

  Future<void> _addComment(Post post, String text) async {
    if (widget.currentUser != null && text.isNotEmpty) {
      await PostManager().addComment(post.id, widget.currentUser!.id, text);
    }
  }

  void _showComments(BuildContext context, Post post) {
  final TextEditingController commentController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Комментарии',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DatabaseHelper().getPostComments(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final comments = snapshot.data ?? [];
                    
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('Пока нет комментариев'),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: comment['avatar_path'] != null
                                ? NetworkImage(comment['avatar_path'])
                                : null,
                            child: comment['avatar_path'] == null 
                                ? const Icon(Icons.person) 
                                : null,
                          ),
                          title: Text('${comment['first_name']} ${comment['last_name']}'),
                          subtitle: Text(comment['text']),
                          trailing: Text(
                            _formatTime(DateTime.parse(comment['created_at'])),
                            style: const TextStyle(fontSize: 10),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _openUserProfile(comment['user_id']);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        focusNode: commentFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Написать комментарий...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) async {
                          if (commentController.text.isNotEmpty) {
                            await _addComment(post, commentController.text);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Комментарий добавлен'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Color(0xFF37474F),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: () async {
                          if (commentController.text.isNotEmpty) {
                            await _addComment(post, commentController.text);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Комментарий добавлен'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                      ),
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
}

    void _openUserProfile(String userId) async {
      if (widget.currentUser == null) return;
      
      final user = await _dbHelper.getUserById(userId);
      if (user != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(
              currentUser: widget.currentUser!,
              targetUser: user,
            ),
          ),
        );
      }
    }

  void _deletePost(Post post) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить пост'),
        content: const Text('Вы уверены, что хотите удалить этот пост?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await PostManager().deletePost(post.id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Пост удален'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _loadPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final posts = PostManager().posts;
          
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Пока нет постов',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              await PostManager().loadPosts();
              setState(() {});
            },
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(posts[index], index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Post post, int index) {
    final bool isAuthor = widget.currentUser?.id == post.authorId;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openUserProfile(post.authorId),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(post.authorAvatar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openUserProfile(post.authorId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(post.time),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isAuthor)
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Удалить'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(post);
                      }
                    },
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          if (post.text != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.text!,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: InteractiveViewer(
                        child: Image.network(
                          post.imageUrl!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
                child: Image.network(
                  post.imageUrl!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Text('Не удалось загрузить изображение'),
                      ),
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.currentUser != null 
                      ? () => _toggleLike(post) 
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likes.toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showComments(context, post),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment,
                        color: Colors.grey.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.comments.toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.reposts.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} д. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'только что';
    }
  }
}