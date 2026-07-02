// Se agrega tab "Inicio" (resumen del dia) y badge de pendientes en "Validar" (pendingReportsNotifier).
// Rediseño visual v2: nav bar con accent alertAmber (color distintivo del rol policia).
// Rediseño visual v2 (BLOQUE 7): NavBounceIcon (pulso al seleccionar tab) y
// AnimatedCountBadge (scale-pop al cambiar el conteo de pendientes).
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../inicio/views/inicio_view.dart';
import '../../map/views/map_view.dart';
import '../../validations/views/validations_view.dart';
import '../../profile/views/profile_view.dart';
import '../../../../roles/user/notifications/views/notifications_view.dart';
import '../../../../core/services/police_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nav_bounce_icon.dart';
import '../../../../core/widgets/animated_count_badge.dart';

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
          color: isDark ? AppTheme.bgSurface : null,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppTheme.alertAmber,
          unselectedItemColor: AppTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _visitedPages.add(index);
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: _navIcon(0, const Icon(Icons.home_outlined)),
              activeIcon: _navIcon(0, const Icon(Icons.home_rounded)),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(1, const Icon(Icons.map_outlined)),
              activeIcon: _navIcon(1, const Icon(Icons.map)),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(2, _buildBadgedIcon(Icons.verified_user_outlined)),
              activeIcon: _navIcon(2, _buildBadgedIcon(Icons.verified_user)),
              label: 'Validar',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(3, const Icon(Icons.notifications_outlined)),
              activeIcon: _navIcon(3, const Icon(Icons.notifications)),
              label: 'Alertas',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(4, const Icon(Icons.person_outline)),
              activeIcon: _navIcon(4, const Icon(Icons.person)),
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
        return AnimatedCountBadge(
          icon: icon,
          count: count,
          badgeColor: AppTheme.alertAmber,
        );
      },
    );
  }

  // Envuelve el icono de un tab con el pulso de seleccion (NavBounceIcon)
  Widget _navIcon(int index, Widget child) {
    return NavBounceIcon(isSelected: _currentIndex == index, child: child);
  }
}
