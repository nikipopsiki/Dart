import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../managers/post_manager.dart';
import 'chat_detail_page.dart';
import 'package:sqflite/sqflite.dart';

class UserProfilePage extends StatefulWidget {
  final User currentUser;
  final User targetUser;

  const UserProfilePage({
    super.key,
    required this.currentUser,
    required this.targetUser,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Post>> _userPosts;
  late Future<String?> _friendStatus;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _userPosts = DatabaseHelper().getUserPosts(widget.targetUser.id);
      _friendStatus = _dbHelper.getFriendStatus(
        widget.currentUser.id,
        widget.targetUser.id,
      );
    });
  }

  Future<void> _sendFriendRequest() async {
    try {
      await _dbHelper.sendFriendRequest(
        widget.currentUser.id,
        widget.targetUser.id,
      );
      
      if (mounted) {
        setState(() {
          _friendStatus = Future.value('pending');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка отправлена'),
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

  Future<void> _acceptFriendRequest() async {
  try {
    await _dbHelper.acceptFriendRequest(
      widget.currentUser.id,
      widget.targetUser.id,
    );
    
    if (mounted) {
      setState(() {
        _friendStatus = Future.value('accepted');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заявка принята'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      if (e.toString().contains('UNIQUE constraint failed') || 
          e.toString().contains('SQLITE_CONSTRAINT_UNIQUE')) {
        setState(() {
          _friendStatus = Future.value('accepted');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы уже друзья'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}

  Future<void> _createChat() async {
    try {
      final chat = await _dbHelper.createChatWithFriend(
        widget.currentUser.id,
        widget.targetUser.id,
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              chat: chat,
              currentUser: widget.currentUser,
            ),
          ),
        );
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              backgroundColor: Color(0xFF37474F),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF37474F),
                        Color(0xFF4A606B),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          image: widget.targetUser.avatarPath != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.targetUser.avatarPath!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.targetUser.avatarPath == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.targetUser.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<String?>(
                        future: _friendStatus,
                        builder: (context, snapshot) {
                          final status = snapshot.data;
                          
                          if (status == 'accepted') {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'В друзьях',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          } else if (status == 'pending') {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Заявка отправлена',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _acceptFriendRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Принять'),
                                ),
                              ],
                            );
                          }
                          
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              actions: [
                FutureBuilder<String?>(
                  future: _friendStatus,
                  builder: (context, snapshot) {
                    if (snapshot.data == 'accepted') {
                      return IconButton(
                        icon: const Icon(Icons.chat, color: Colors.white),
                        onPressed: _createChat,
                        tooltip: 'Написать сообщение',
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Посты'),
                    Tab(text: 'Информация'),
                  ],
                  labelColor: Color(0xFF37474F),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF37474F),
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            FutureBuilder<List<Post>>(
              future: _userPosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data ?? [];

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
                          'У пользователя пока нет постов',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(posts[index]);
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, color: Color(0xFF37474F),),
                      title: const Text('Имя'),
                      subtitle: Text(widget.targetUser.fullName),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone, color: Color(0xFF37474F),),
                      title: const Text('Телефон'),
                      subtitle: Text(
                        widget.targetUser.isPhoneHidden && 
                        widget.currentUser.id != widget.targetUser.id
                            ? 'Скрыт'
                            : widget.targetUser.phoneNumber,
                      ),
                    ),
                    if (widget.targetUser.email != null) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email, color: Color(0xFF37474F),),
                        title: const Text('Email'),
                        subtitle: Text(widget.targetUser.email!),
                      ),
                    ],
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Color(0xFF37474F),),
                      title: const Text('На сайте с'),
                      subtitle: Text(
                        '${widget.targetUser.registrationDate.day}.${widget.targetUser.registrationDate.month}.${widget.targetUser.registrationDate.year}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FutureBuilder<String?>(
        future: _friendStatus,
        builder: (context, snapshot) {
          if (snapshot.data == null && widget.currentUser.id != widget.targetUser.id) {
            return FloatingActionButton.extended(
              onPressed: _sendFriendRequest,
              icon: const Icon(Icons.person_add),
              label: const Text('Добавить в друзья'),
              backgroundColor: Color(0xFF37474F),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.text != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(post.text!),
            ),
          if (post.imageUrl != null)
            Image.network(
              post.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Center(child: Text('Ошибка загрузки')),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(post.likes.toString()),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.comment, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(post.comments.toString()),
                  ],
                ),
                const Spacer(),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
