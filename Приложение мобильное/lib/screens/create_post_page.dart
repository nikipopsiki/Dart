import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../managers/post_manager.dart';

class CreatePostPage extends StatefulWidget {
  final User user;

  const CreatePostPage({super.key, required this.user});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;

  void _createPost() async {  
    if (_textController.text.isEmpty && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте текст или изображение'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: widget.user.id,
      authorName: widget.user.fullName,
      authorAvatar: widget.user.avatarPath ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      time: DateTime.now(),
      text: _textController.text.isNotEmpty ? _textController.text : null,
      imageUrl: _imageUrl,
      likes: 0,
      comments: 0,
      reposts: 0,
    );

    await PostManager().addPost(newPost);

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пост опубликован!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать пост'),
        backgroundColor: Color(0xFF37474F),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: Text(
              _isLoading ? 'Публикация...' : 'Опубликовать',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.user.avatarPath != null
                      ? NetworkImage(widget.user.avatarPath!)
                      : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сейчас',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Что у вас нового?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => _imageUrl = value,
              decoration: InputDecoration(
                hintText: 'URL изображения (необязательно)',
                prefixIcon: const Icon(Icons.image),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_imageUrl != null && _imageUrl!.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_imageUrl!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}