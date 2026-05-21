import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import 'chat_detail_page.dart';
import 'search_users_page.dart';
import 'user_profile_page.dart';

class ChatsPage extends StatefulWidget {
  final User currentUser;

  const ChatsPage({super.key, required this.currentUser});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Chat>> _chatsFuture;
  late Future<List<User>> _friendsFuture;
  
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _chatsFuture = _dbHelper.getUserChats(widget.currentUser.id);
      _friendsFuture = _dbHelper.getFriends(widget.currentUser.id);
    });
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      setState(() => _isSearching = true);
      _searchFriends();
    }
  }

  Future<void> _searchFriends() async {
    final results = await _dbHelper.searchFriends(
      widget.currentUser.id,
      query: _searchController.text,
    );
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  Future<void> _openSearchUsersPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchUsersPage(
          currentUser: widget.currentUser,
        ),
      ),
    );
    
    if (result != null && result is Chat && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chat: result,
            currentUser: widget.currentUser,
          ),
        ),
      );
      _loadData();
    }
  }
  Widget _buildFriendsSection() {
    return FutureBuilder<List<User>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = snapshot.data ?? [];
        
        if (friends.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'У вас пока нет друзей',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: _openSearchUsersPage,
                    child: const Text('Найти друзей'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Друзья онлайн',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return _buildFriendChip(friend);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildFriendChip(User friend) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(
              currentUser: widget.currentUser,
              targetUser: friend,
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: friend.avatarPath != null
                      ? NetworkImage(friend.avatarPath!)
                      : null,
                  child: friend.avatarPath == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              friend.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text('Ничего не найдено'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Результаты поиска',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final user = _searchResults[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.avatarPath != null
                    ? NetworkImage(user.avatarPath!)
                    : null,
                child: user.avatarPath == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user.fullName),
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
      ],
    );
  }
  Widget _buildChatTile(Chat chat) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: chat.avatarPath != null
                ? NetworkImage(chat.avatarPath!)
                : null,
            child: chat.avatarPath == null ? const Icon(Icons.person) : null,
          ),
          if (chat.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chat.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chat.lastMessage ?? 'Нет сообщений',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageTime != null)
            Text(
              _formatTime(chat.lastMessageTime!),
              style: TextStyle(
                fontSize: 12,
                color: chat.unreadCount > 0 ? Color(0xFF37474F) : Colors.grey,
              ),
            ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF37474F),
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              chat: chat,
              currentUser: widget.currentUser,
            ),
          ),
        );
      },
    );
  }
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}д';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'только что';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Color(0xFF37474F),
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Поиск друзей...',
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF37474F)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.person_add, color: Color(0xFF37474F)),
                            onPressed: _openSearchUsersPage,
                            tooltip: 'Добавить друга',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isSearching)
            SliverToBoxAdapter(
              child: _buildSearchResults(),
            )
          else ...[
            SliverToBoxAdapter(
              child: _buildFriendsSection(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Чаты',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
            ),
            FutureBuilder<List<Chat>>(
              future: _chatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final chats = snapshot.data ?? [];
                
                if (chats.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('У вас пока нет чатов'),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildChatTile(chats[index]);
                    },
                    childCount: chats.length,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}