import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/database_helper.dart';
import 'models/user_model.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/chats_page.dart';
import 'screens/profile_page.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database;
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Социальная сеть',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFF37474F),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarThemeData(
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: const CardThemeData( 
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            tabBarTheme: const TabBarThemeData( 
              labelColor: Color(0xFF37474F),
              unselectedLabelColor: Colors.grey,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Color(0xFF37474F),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: AppBarThemeData(
              elevation: 0,
              backgroundColor: Colors.grey[900],
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              color: Colors.grey[850],
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: Colors.deepPurple.shade200,
              unselectedLabelColor: Colors.grey.shade400,
            ),
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const LoginPage(),
        );
      },
    );
  }
}

class AppBarExample extends StatelessWidget {
  final User user;

  const AppBarExample({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        bottomNavigationBar: BottomAppBar(
          child: TabBar(
            tabs: const <Widget>[
              Tab(icon: Icon(Icons.cottage), text: 'Главная'),
              Tab(icon: Icon(Icons.comment), text: 'Чаты'),
              Tab(icon: Icon(Icons.account_box), text: 'Профиль'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            HomePage(currentUser: user),
            ChatsPage(currentUser: user),
            ProfilePage(user: user),
          ],
        ),
      ),
    );
  }
}