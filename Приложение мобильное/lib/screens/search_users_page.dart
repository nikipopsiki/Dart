import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import 'user_profile_page.dart';
import 'chat_detail_page.dart';

class SearchUsersPage extends StatefulWidget {
  final User currentUser;

  const SearchUsersPage({super.key, required this.currentUser});

  @override
  State<SearchUsersPage> createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<User> _searchResults = [];
  List<User> _friendRequests = [];
  bool _isLoading = false;
  Map<String, String?> _friendStatuses = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadFriendRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendRequests() async {
    final requests = await _dbHelper.getFriendRequests(widget.currentUser.id);
    if (mounted) {
      setState(() {
        _friendRequests = requests;
      });
    }
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _performSearch() async {
    if (_searchController.text.length < 2) return;

    setState(() => _isLoading = true);

    try {
      final results = await _dbHelper.searchUsers(
        query: _searchController.text,
        userId: widget.currentUser.id,
      );
      
      final Map<String, String?> statuses = {};
      for (var user in results) {
        statuses[user.id] = await _dbHelper.getFriendStatus(
          widget.currentUser.id, 
          user.id
        );
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _friendStatuses = statuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка поиска: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(User friend) async {
    try {
      await _dbHelper.acceptFriendRequest(
        widget.currentUser.id,
        friend.id,
      );
      
      if (mounted) {
        setState(() {
          _friendRequests.removeWhere((u) => u.id == friend.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Вы приняли заявку от ${friend.firstName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(User friend) async {
    try {
      await _dbHelper.rejectFriendRequest(
        widget.currentUser.id,
        friend.id,
      );
      
      if (mounted) {
        setState(() {
          _friendRequests.removeWhere((u) => u.id == friend.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заявка от ${friend.firstName} отклонена'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(User targetUser) async {
    try {
      await _dbHelper.sendFriendRequest(widget.currentUser.id, targetUser.id);
      
      setState(() {
        _friendStatuses[targetUser.id] = 'pending';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заявка отправлена ${targetUser.firstName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _createChat(User friend) async {
    try {
      final chat = await _dbHelper.createChatWithFriend(
        widget.currentUser.id, 
        friend.id
      );
      
      if (mounted) {
        Navigator.pop(context, chat);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания чата: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск пользователей'),
        backgroundColor: Color(0xFF37474F),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Поиск'),
            Tab(text: 'Заявки'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Введите ID, телефон или имя...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Введите имя или номер телефона'
                                      : 'Ничего не найдено',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              final status = _friendStatuses[user.id];
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user.avatarPath != null
                                      ? NetworkImage(user.avatarPath!)
                                      : null,
                                  child: user.avatarPath == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(user.fullName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${user.id}'),
                                    if (user.email != null) Text(user.email!),
                                  ],
                                ),
                                trailing: _buildActionButton(user, status),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfilePage(
                                        currentUser: widget.currentUser,
                                        targetUser: user,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
          _friendRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет входящих заявок',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _friendRequests.length,
                  itemBuilder: (context, index) {
                    final user = _friendRequests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarPath != null
                              ? NetworkImage(user.avatarPath!)
                              : null,
                          child: user.avatarPath == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user.fullName),
                        subtitle: Text('ID: ${user.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptRequest(user),
                              tooltip: 'Принять',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectRequest(user),
                              tooltip: 'Отклонить',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfilePage(
                                currentUser: widget.currentUser,
                                targetUser: user,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildActionButton(User user, String? status) {
    if (status == 'accepted') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat, color: Color(0xFF37474F)),
            onPressed: () => _createChat(user),
            tooltip: 'Написать сообщение',
          ),
          IconButton(
            icon: const Icon(Icons.person_remove, color: Colors.red),
            onPressed: () {
            },
            tooltip: 'Удалить из друзей',
          ),
        ],
      );
    } else if (status == 'pending') {
      return const Chip(
        label: Text('Заявка отправлена'),
        backgroundColor: Colors.orange,
        labelStyle: TextStyle(color: Colors.white),
        avatar: Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _sendFriendRequest(user),
        icon: const Icon(Icons.person_add, size: 16),
        label: const Text('Добавить'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF37474F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
  }
}