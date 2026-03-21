import 'package:flutter/material.dart';
import '../../auth/views/login_view.dart';
import '../../../core/theme/app_theme.dart';

class ProfileView extends StatelessWidget {
  final String? userName;
  final String? userRole;

  const ProfileView({super.key, this.userName, this.userRole});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              userName ?? 'Mi Perfil',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (userRole != null)
              Text(
                'Rol: ${userRole!.toUpperCase()}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const SizedBox(height: 30),
            
            // Toggle de Modo Oscuro/Claro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.themeNotifier,
                builder: (context, currentMode, child) {
                  final isDark = currentMode == ThemeMode.dark;
                  return SwitchListTile(
                    title: const Text('Modo Oscuro'),
                    secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    value: isDark,
                    onChanged: (value) {
                      AppTheme.themeNotifier.value = 
                          value ? ThemeMode.dark : ThemeMode.light;
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Theme.of(context).cardColor,
                  );
                },
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Lógica de cerrar sesión
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

