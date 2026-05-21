import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../managers/post_manager.dart';
import 'create_post_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Post> _userPosts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserPosts();
  }

  void _loadUserPosts() {
    _userPosts = PostManager().posts.where((post) => post.authorId == widget.user.id).toList();
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
                          image: widget.user.avatarPath != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.user.avatarPath!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.user.avatarPath == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${widget.user.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
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
            _userPosts.isEmpty
                ? Center(
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
                          'У вас пока нет постов',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Создайте свой первый пост!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _userPosts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_userPosts[index]);
                    },
                  ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.phone, color: Color(0xFF37474F),),
                          title: const Text('Телефон'),
                          subtitle: Text(
                            widget.user.isPhoneHidden ? '********' : widget.user.phoneNumber,
                          ),
                        ),
                        const Divider(),
                        if (widget.user.email != null)
                          ListTile(
                            leading: const Icon(Icons.email, color: Color(0xFF37474F),),
                            title: const Text('Email'),
                            subtitle: Text(widget.user.email!),
                          ),
                        ListTile(
                          leading: const Icon(Icons.calendar_today, color: Color(0xFF37474F),),
                          title: const Text('На сайте с'),
                          subtitle: Text(
                            '${widget.user.registrationDate.day}.${widget.user.registrationDate.month}.${widget.user.registrationDate.year}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(user: widget.user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Настройки'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF37474F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostPage(user: widget.user),
                  ),
                ).then((_) {
                  setState(() {
                    _loadUserPosts();
                  });
                });
              },
              backgroundColor: Color(0xFF37474F),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
                    Icon(
                      Icons.favorite,
                      color: post.isLiked ? Colors.red : Colors.grey.shade400,
                      size: 16,
                    ),
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