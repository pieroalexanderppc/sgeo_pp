import 'package:flutter/material.dart';
import 'package:sgeo_pp/features/auth/views/login_view.dart';
import 'package:sgeo_pp/features/map/views/map_view.dart';
import 'package:sgeo_pp/features/reports/views/my_reports_view.dart';
import 'package:sgeo_pp/features/profile/views/profile_view.dart';

class HomeView extends StatefulWidget {
  final String userRole; // "admin", "policia", o "ciudadano"
  final String userName;

  const HomeView({super.key, required this.userRole, required this.userName});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MapView(),
    MyReportsView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mis Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'policia':
        return Icons.local_police;
      default:
        return Icons.person;
    }
  }
}
