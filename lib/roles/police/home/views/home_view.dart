// Se agrega tab "Inicio" (resumen del dia) y badge de pendientes en "Validar" (pendingReportsNotifier).
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../inicio/views/inicio_view.dart';
import '../../map/views/map_view.dart';
import '../../validations/views/validations_view.dart';
import '../../profile/views/profile_view.dart';
import '../../../../roles/user/notifications/views/notifications_view.dart';
import '../../../../core/services/police_service.dart';
import '../../../../core/theme/app_theme.dart';

class PoliceHomeView extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userId;

  const PoliceHomeView({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userId,
  });

  @override
  State<PoliceHomeView> createState() => _PoliceHomeViewState();
}

class _PoliceHomeViewState extends State<PoliceHomeView> {
  int _currentIndex = 0;
  final Set<int> _visitedPages = {0};
  LatLng? _selectedLocationToNavigate;

  @override
  void initState() {
    super.initState();
    PoliceService.refreshPendingCount();
  }

  List<Widget> _buildPages() {
    return [
      const PoliceInicioView(),
      PoliceMapView(
        userId: widget.userId,
        initialLocation: _selectedLocationToNavigate,
      ),
      ValidationsView(
        userId: widget.userId,
        onNavigateToMap: (LatLng loc) {
          setState(() {
            _selectedLocationToNavigate = loc;
            _currentIndex = 1;
            _visitedPages.add(1);
          });
        },
      ),
      const NotificationsView(),
      PoliceProfileView(
        userId: widget.userId,
        userName: widget.userName,
        userRole: widget.userRole,
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
        children: List.generate(
          5,
          (index) => _visitedPages.contains(index)
              ? pages[index]
              : const SizedBox.shrink(),
        ),
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
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _visitedPages.add(index);
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: _buildBadgedIcon(Icons.verified_user_outlined),
              activeIcon: _buildBadgedIcon(Icons.verified_user),
              label: 'Validar',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alertas',
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

  Widget _buildBadgedIcon(IconData icon) {
    return ValueListenableBuilder<int>(
      valueListenable: PoliceService.pendingReportsNotifier,
      builder: (context, count, _) {
        if (count <= 0) return Icon(icon);
        return Badge(
          backgroundColor: AppTheme.alertAmber,
          label: Text(count > 9 ? '9+' : count.toString()),
          child: Icon(icon),
        );
      },
    );
  }
}
