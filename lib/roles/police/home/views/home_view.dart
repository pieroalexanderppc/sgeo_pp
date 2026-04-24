import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../map/views/map_view.dart';
import '../../validations/views/validations_view.dart';
import '../../profile/views/profile_view.dart';
import '../../../../roles/user/notifications/views/notifications_view.dart';

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

  List<Widget> _buildPages() {
    return [
      PoliceMapView(
        userId: widget.userId,
        initialLocation: _selectedLocationToNavigate,
      ),
      ValidationsView(
        userId: widget.userId,
        onNavigateToMap: (LatLng loc) {
          setState(() {
            _selectedLocationToNavigate = loc;
            _currentIndex = 0;
            _visitedPages.add(0);
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _visitedPages.add(index);
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Validar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
