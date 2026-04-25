import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_card.dart';

class UsersManageView extends StatefulWidget {
  const UsersManageView({super.key});

  @override
  State<UsersManageView> createState() => _UsersManageViewState();
}

class _UsersManageViewState extends State<UsersManageView> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'https://sgeo-backend-production.up.railway.app/api/usuarios',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() => _users = data['usuarios'] ?? []);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Gestión de Personal'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded), 
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_alt_outlined, size: 60, color: isDark ? AppTheme.textMuted : Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No hay usuarios registrados',
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondary : Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                itemCount: _users.length,
                itemBuilder: (ctx, i) {
                  final u = _users[i];
                  final rol = (u['rol'] ?? 'CIUDADANO').toString().toUpperCase();

                  IconData roleIcon = Icons.person_rounded;
                  Color roleColor = AppTheme.accentBlue;

                  if (rol == 'POLICIA') {
                    roleIcon = Icons.local_police_rounded;
                    roleColor = AppTheme.successGreen;
                  } else if (rol == 'ADMIN' || rol == 'ADMINISTRADOR') {
                    roleIcon = Icons.admin_panel_settings_rounded;
                    roleColor = AppTheme.alertRed;
                  }

                  return SafetyCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(roleIcon, color: roleColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        
                        // Datos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u['nombre'] ?? 'Sin Nombre',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark ? AppTheme.textPrimary : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                u['email'] ?? 'Sin Correo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.textSecondary : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  rol,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: roleColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Acciones
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.alertRed.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.block_rounded, color: AppTheme.alertRed, size: 20),
                              ),
                              tooltip: "Suspender",
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('La suspensión de usuarios estará disponible próximamente.'),
                                    backgroundColor: AppTheme.alertAmber,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 50 * i), duration: 300.ms)
                  .slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut);
                },
              ),
      ),
    );
  }
}
