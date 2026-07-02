// Se agrega tab "Solicitudes" con badge de policias pendientes (pendingCountNotifier).
// Rediseño visual v2: nav bar con accent accentCyan (mismo accent principal del sistema).
// Rediseño visual v2 (BLOQUE 7): NavBounceIcon (pulso al seleccionar tab) y
// AnimatedCountBadge (scale-pop al cambiar el conteo de solicitudes pendientes).
import 'package:flutter/material.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../approvals/views/approvals_view.dart';
import '../../users/views/users_manage_view.dart';
import '../../profile/views/profile_view.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nav_bounce_icon.dart';
import '../../../../core/widgets/animated_count_badge.dart';

class AdminHomeView extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userId;

  const AdminHomeView({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userId,
  });

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  int _currentIndex = 0;
  final Set<int> _visitedPages = {0};

  @override
  void initState() {
    super.initState();
    AdminService.refreshPendingCount();
  }

  List<Widget> _buildPages() {
    return [
      DashboardView(
        onNavigateToApprovals: () {
          setState(() {
            _currentIndex = 1;
            _visitedPages.add(1);
          });
        },
      ),
      const ApprovalsView(),
      const UsersManageView(),
      AdminProfileView(
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
          4,
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
          selectedItemColor: AppTheme.accentCyan,
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
              icon: _navIcon(0, const Icon(Icons.dashboard_outlined)),
              activeIcon: _navIcon(0, const Icon(Icons.dashboard_rounded)),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(1, _buildBadgedIcon(Icons.fact_check_outlined)),
              activeIcon: _navIcon(
                1,
                _buildBadgedIcon(Icons.fact_check_rounded),
              ),
              label: 'Solicitudes',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(2, const Icon(Icons.people_outline_rounded)),
              activeIcon: _navIcon(2, const Icon(Icons.people_alt_rounded)),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(
                3,
                const Icon(Icons.admin_panel_settings_outlined),
              ),
              activeIcon: _navIcon(
                3,
                const Icon(Icons.admin_panel_settings_rounded),
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  // Envuelve el icono de "Solicitudes" con un badge rojo cuando hay policias pendientes
  Widget _buildBadgedIcon(IconData icon) {
    return ValueListenableBuilder<int>(
      valueListenable: AdminService.pendingCountNotifier,
      builder: (context, count, _) {
        return AnimatedCountBadge(
          icon: icon,
          count: count,
          badgeColor: AppTheme.alertRed,
        );
      },
    );
  }

  // Envuelve el icono de un tab con el pulso de seleccion (NavBounceIcon)
  Widget _navIcon(int index, Widget child) {
    return NavBounceIcon(isSelected: _currentIndex == index, child: child);
  }
}
