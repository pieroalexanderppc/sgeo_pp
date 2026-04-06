import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/login_view.dart';
import 'features/home/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  
  String? userId;
  String? userName;
  String? userRole;

  if (isLoggedIn) {
    userId = prefs.getString('user_id');
    userName = prefs.getString('user_name');
    userRole = prefs.getString('user_role');
  }

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    userId: userId ?? '',
    userName: userName ?? '',
    userRole: userRole ?? 'ciudadano',
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userId;
  final String userName;
  final String userRole;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'SGEO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: isLoggedIn 
                ? HomeView(userId: userId, userName: userName, userRole: userRole) 
                : const LoginView(),
        );
      },
    );
  }
}
