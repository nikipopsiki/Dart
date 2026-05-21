  import 'package:flutter/material.dart';
  import '../models/user_model.dart';
  import '../database/database_helper.dart';
  import 'login_page.dart';
  import 'package:provider/provider.dart';
  import '../providers/theme_provider.dart';

  class SettingsPage extends StatefulWidget {
    final User user;

    const SettingsPage({super.key, required this.user});

    @override
    State<SettingsPage> createState() => _SettingsPageState();
  }

  class _SettingsPageState extends State<SettingsPage> {
    late bool _isPhoneHidden;
    late bool _isDarkMode;

    @override
    void initState() {
      super.initState();
      _isPhoneHidden = widget.user.isPhoneHidden;
      _isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    }

    Future<void> _logout() async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выход из аккаунта'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Выйти'),
            ),
          ],
        ),
      );

      if (shouldLogout == true && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы вышли из аккаунта'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Настройки'),
          backgroundColor: Color(0xFF37474F),
          foregroundColor: Colors.white,
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('Скрыть номер телефона'),
              subtitle: const Text('Ваш номер не будут видеть другие пользователи'),
              value: _isPhoneHidden,
              onChanged: (bool value) async {
                setState(() {
                  _isPhoneHidden = value;
                  widget.user.isPhoneHidden = value;
                });
                
                await DatabaseHelper().updateUser(widget.user);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value 
                        ? 'Номер телефона скрыт' 
                        : 'Номер телефона виден всем'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              activeColor: Color(0xFF37474F),
            ),
            const Divider(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Темная тема'),
                  subtitle: const Text('Переключить оформление приложения'),
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) async {
                    await themeProvider.toggleTheme(value);
                    setState(() {
                      _isDarkMode = value;
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode 
                          ? Colors.grey.shade800 
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  activeColor: Color(0xFFE3F2FD),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Уведомления'),
              trailing: const Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Язык'),
              trailing: const Text('Русский'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('О приложении'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Социальная сеть',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.chat, size: 50),
                  children: const [
                    Text('Социальное приложение с чатами и постами'),
                  ],
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Выйти из аккаунта',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
          ],
        ),
      );
    }
  }