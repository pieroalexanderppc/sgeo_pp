import 'package:flutter/material.dart';
import 'package:sgeo_pp/features/map/views/map_view.dart';
import 'package:sgeo_pp/features/reports/views/my_reports_view.dart';
import 'package:sgeo_pp/features/profile/views/profile_view.dart';
import 'package:sgeo_pp/features/news/views/news_view.dart';
import 'package:sgeo_pp/features/notifications/views/notifications_view.dart';

class HomeView extends StatefulWidget {
  final String userRole; // "admin", "policia", o "ciudadano"
  final String userName;
  final String userId;

  const HomeView({super.key, required this.userRole, required this.userName, required this.userId});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MapView(userId: widget.userId),
      const NewsView(),
      const NotificationsView(),
      MyReportsView(userId: widget.userId),
      ProfileView(userName: widget.userName, userRole: widget.userRole),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // Esto es muy importante cuando hay mÃ¡s de 3 items
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
            icon: Icon(Icons.newspaper),
            label: 'Noticias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mi Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
