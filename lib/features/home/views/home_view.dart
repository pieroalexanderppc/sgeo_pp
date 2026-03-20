import 'package:flutter/material.dart';
import 'package:sgeo_pp/features/auth/views/login_view.dart';
import 'package:sgeo_pp/features/map/views/map_view.dart'; // Asegúrate de ajustar importaciones si cambian

class HomeView extends StatelessWidget {
  final String userRole; // "admin", "policia", o "ciudadano"
  final String userName;

  const HomeView({super.key, required this.userRole, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SGEO - Mapa Principal'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text('Rol: ${userRole.toUpperCase()}'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  _getRoleIcon(userRole),
                  size: 40,
                  color: Colors.blue.shade900,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
              ),
            ),
            if (userRole == 'admin' || userRole == 'policia')
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Panel de Control Sidpol'),
                onTap: () {
                  // Navegar a estadísticas (futuro)
                },
              ),
            if (userRole == 'admin')
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Gestión de Usuarios'),
                onTap: () {
                  // Navegar a ABM usuarios (futuro)
                },
              ),
            if (userRole == 'ciudadano' || userRole == 'policia')
              ListTile(
                leading: const Icon(Icons.add_alert),
                title: const Text('Reportar Incidente'),
                onTap: () {
                  // Navegar a formulario de reporte (futuro)
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      // El mapa es compartido por todos, aquí lo inyectamos en el cuerpo
      body: const MapView(),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'policia':
        return Icons.local_police;
      default:
        return Icons.person;
    }
  }
}