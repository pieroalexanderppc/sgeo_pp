import 'package:flutter/material.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../users/views/users_manage_view.dart';
import '../../profile/views/profile_view.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _visitedPages.add(index);
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
