// Se agrega badge de notificaciones no leidas y disparo automatico del tutorial en el primer ingreso (rol ciudadano).
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../map/views/map_view.dart';
import '../../reports/views/my_reports_view.dart';
import '../../profile/views/profile_view.dart';
import '../../news/views/news_view.dart';
import '../../notifications/views/notifications_view.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/services/notifications_storage_service.dart';
import '../../../../core/services/tutorial_service.dart';
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
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _mapFocusLocation = widget.initialLocation;
    GeofenceService.startTracking();
    _loadUnreadCount();
    NotificationsStorageService.updateNotifier.addListener(_onNotificationsChanged);
    _checkFirstTimeTutorial();
  }

  void _onNotificationsChanged() {
    if (mounted) _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationsStorageService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifications = count);
  }

  // Dispara el tutorial guiado una sola vez, la primera vez que el ciudadano entra al Home
  Future<void> _checkFirstTimeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_map_tutorial') ?? false;
    if (!hasSeenTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) TutorialService.forceStartTutorial('all');
      });
    }
  }

  @override
  void dispose() {
    GeofenceService.stopTracking();
    NotificationsStorageService.updateNotifier.removeListener(_onNotificationsChanged);
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
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'Noticias',
            ),
            BottomNavigationBarItem(
              icon: _buildBadgedIcon(Icons.notifications_outlined, _unreadNotifications),
              activeIcon: _buildBadgedIcon(Icons.notifications, _unreadNotifications),
              label: 'Alertas',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Reportes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  // Envuelve un icono del nav bar con un badge numerico cuando hay notificaciones sin leer
  Widget _buildBadgedIcon(IconData icon, int count) {
    if (count <= 0) return Icon(icon);
    return Badge(
      label: Text(count > 9 ? '9+' : count.toString()),
      child: Icon(icon),
    );
  }
}
