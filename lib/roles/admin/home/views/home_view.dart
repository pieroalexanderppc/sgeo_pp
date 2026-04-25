import 'package:flutter/material.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../users/views/users_manage_view.dart';
import '../../profile/views/profile_view.dart';
import '../../../../core/theme/app_theme.dart';

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

  List<Widget> _buildPages() {
    return [
      const DashboardView(),
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
          3,
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
