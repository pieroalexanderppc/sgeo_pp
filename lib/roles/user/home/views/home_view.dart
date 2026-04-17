import 'package:flutter/material.dart';
import '../../map/views/map_view.dart';
import '../../reports/views/my_reports_view.dart';
import '../../profile/views/profile_view.dart';
import '../../news/views/news_view.dart';
import '../../notifications/views/notifications_view.dart';
import '../../../../core/services/geofence_service.dart';

import 'package:latlong2/latlong.dart';

class HomeView extends StatefulWidget {
  final String userRole; // "admin", "policia", o "ciudadano"
  final String userName;
  final String userId;
  final LatLng? initialLocation;

  const HomeView({super.key, required this.userRole, required this.userName, required this.userId, this.initialLocation});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final Set<int> _visitedPages = {0};

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Encender protector de GPS en segundo/primer plano al iniciar el Home de la app
    GeofenceService.startTracking();

    _pages = [
      MapView(userId: widget.userId, initialLocation: widget.initialLocation),
      const NewsView(),
      const NotificationsView(),
      MyReportsView(userId: widget.userId),
      ProfileView(
        userId: widget.userId,
        userName: widget.userName, 
        userRole: widget.userRole,
      ),
    ];
  }

  @override
  void dispose() {
    GeofenceService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, (index) => _visitedPages.contains(index) ? _pages[index] : const SizedBox.shrink()),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // Esto es muy importante cuando hay más de 3 items
        onTap: (index) {
          setState(() {
            _currentIndex = index;
              _visitedPages.add(index);
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
            label: 'Reportes',
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

