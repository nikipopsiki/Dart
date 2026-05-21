import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post_model.dart';

class PostManager extends ChangeNotifier {
  static final PostManager _instance = PostManager._internal();
  factory PostManager() => _instance;
  PostManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Post> _posts = [];
  String? _currentUserId;

  List<Post> get posts => List.unmodifiable(_posts);

  Future<void> loadPosts({String? userId}) async {
    if (userId != null) {
      _posts = await _dbHelper.getUserPosts(userId);
    } else {
      _posts = await _dbHelper.getAllPosts();
    }
    notifyListeners();
  }

  Future<void> addPost(Post post) async {
    await _dbHelper.insertPost(post);
    await loadPosts(userId: _currentUserId);
  }

  Future<void> deletePost(String postId) async {
    await _dbHelper.deletePost(postId);
    await loadPosts(userId: _currentUserId);
  }

  Future<void> toggleLike(String postId, String userId) async {
    await _dbHelper.toggleLike(postId, userId);
    
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final isLiked = await _dbHelper.isPostLiked(postId, userId);
      final updatedPost = _posts[index].copyWith(
        likes: _posts[index].likes + (isLiked ? 1 : -1),
        isLiked: isLiked,
      );
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, String userId, String text) async {
    await _dbHelper.addComment(postId, userId, text);
    
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(
        comments: _posts[index].comments + 1,
      );
      notifyListeners();
    }
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }
}