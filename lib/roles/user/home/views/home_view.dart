import 'package:flutter/material.dart';
import '../../map/views/map_view.dart';
import '../../reports/views/my_reports_view.dart';
import '../../profile/views/profile_view.dart';
import '../../news/views/news_view.dart';
import '../../notifications/views/notifications_view.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/theme/app_theme.dart';

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
  LatLng? _mapFocusLocation;

  @override
  void initState() {
    super.initState();
    _mapFocusLocation = widget.initialLocation;
    GeofenceService.startTracking();
  }

  @override
  void dispose() {
    GeofenceService.stopTracking();
    super.dispose();
  }

  List<Widget> _buildPages() {
    return [
      MapView(userId: widget.userId, initialLocation: _mapFocusLocation),
      const NewsView(),
      const NotificationsView(),
      MyReportsView(
        userId: widget.userId,
        onNavigateToMap: (latLng) {
          setState(() {
            _mapFocusLocation = latLng;
            _currentIndex = 0;
            _visitedPages.add(0);
          });
        },
      ),
      ProfileView(
        userId: widget.userId,
        userName: widget.userName,
        userRole: widget.userRole,
        onNavigateToMap: () {
          setState(() {
            _currentIndex = 0;
            _visitedPages.add(0);
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _buildPages();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, (index) => _visitedPages.contains(index) ? pages[index] : const SizedBox.shrink()),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderTactical : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
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
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'Noticias',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alertas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Reportes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
