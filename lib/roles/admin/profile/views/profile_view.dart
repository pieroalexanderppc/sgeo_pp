import 'package:flutter/material.dart';
import '../../../../features/auth/views/login_view.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_card.dart';
import '../../../../core/widgets/safety_button.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';

class AdminProfileView extends StatefulWidget {
  final String userId;
  final String userName;
  final String userRole;

  const AdminProfileView({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<AdminProfileView> {
  bool _isLoading = true;
  bool _isEditing = false;

  String? _nombre;
  String? _email;
  String? _telefono;
  String? _rol;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nombre = widget.userName;
    _rol = widget.userRole;
    _nameController = TextEditingController(text: _nombre);
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final response = await http.get(
        Uri.parse('https://sgeo-backend-production.up.railway.app/api/usuarios/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _nombre = data['user']['nombre'] ?? widget.userName;
            _email = data['user']['email'];
            _telefono = data['user']['telefono'] ?? '';
            _rol = data['user']['rol'] ?? widget.userRole;

            _nameController.text = _nombre ?? '';
            _emailController.text = _email ?? '';
            _phoneController.text = _telefono ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil admin: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('https://sgeo-backend-production.up.railway.app/api/usuarios/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'telefono': _phoneController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _nombre = _nameController.text.trim();
          _email = _emailController.text.trim();
          _telefono = _phoneController.text.trim();
          _isEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Perfil administrador actualizado con éxito'), backgroundColor: AppTheme.successGreen),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Error al actualizar datos'), backgroundColor: AppTheme.alertRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de red: $e'), backgroundColor: AppTheme.alertRed));
      }
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
        title: const Text('Panel de Administrador'),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    _isEditing = false;
                    _nameController.text = _nombre ?? '';
                    _emailController.text = _email ?? '';
                    _phoneController.text = _telefono ?? '';
                  } else {
                    _isEditing = true;
                  }
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  // --- AVATAR TÁCTICO ADMIN ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.alertRed.withValues(alpha: 0.5) : AppTheme.alertRed,
                          width: 2,
                        ),
                        boxShadow: isDark ? [
                          BoxShadow(
                            color: AppTheme.alertRed.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ] : null,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: isDark ? AppTheme.bgElevated : Colors.red.shade50,
                        child: Icon(
                          Icons.admin_panel_settings_rounded, 
                          size: 55, 
                          color: isDark ? Colors.redAccent.shade100 : AppTheme.alertRed
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  ),
                  const SizedBox(height: 16),
                  
                  if (!_isEditing) ...[
                    Text(
                      _nombre ?? 'Administrador',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.textPrimary : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.alertRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        (_rol ?? 'ADMINISTRADOR').toUpperCase(),
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w800, 
                          color: isDark ? Colors.redAccent.shade100 : AppTheme.alertRed,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],

                  const SizedBox(height: 32),

                  // --- DATOS PERSONALES ---
                  SafetyCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DATOS DEL SISTEMA",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.redAccent.shade100 : AppTheme.alertRed,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileItem(
                          icon: Icons.badge_outlined,
                          title: 'Nombre Administrativo',
                          value: _nombre ?? '-',
                          controller: _nameController,
                          isEditing: _isEditing,
                          isDark: isDark,
                        ),
                        const Divider(height: 24),
                        _buildProfileItem(
                          icon: Icons.email_outlined,
                          title: 'Correo de Acceso',
                          value: (_email == null || _email!.isEmpty) ? 'No especificado' : _email!,
                          controller: _emailController,
                          isEditing: _isEditing,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const Divider(height: 24),
                        _buildProfileItem(
                          icon: Icons.phone_outlined,
                          title: 'Teléfono',
                          value: (_telefono == null || _telefono!.isEmpty) ? 'No especificado' : _telefono!,
                          controller: _phoneController,
                          isEditing: _isEditing,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: SafetyButton.outline(
                            label: 'Cancelar',
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _nameController.text = _nombre ?? '';
                                _emailController.text = _email ?? '';
                                _phoneController.text = _telefono ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SafetyButton.danger(
                            label: 'Guardar Cambios',
                            icon: Icons.save_rounded,
                            onPressed: _saveChanges,
                          ),
                        ),
                      ],
                    ).animate().fadeIn()
                  else ...[
                    // --- PREFERENCIAS ---
                    SafetyCard(
                      padding: EdgeInsets.zero,
                      child: ValueListenableBuilder<ThemeMode>(
                        valueListenable: AppTheme.themeNotifier,
                        builder: (context, currentMode, child) {
                          final isDarkMode = currentMode == ThemeMode.dark;
                          return SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(
                              'Modo Táctico (Oscuro)',
                              style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppTheme.textPrimary : Colors.black87),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.indigo.withValues(alpha: 0.2) : Colors.indigo.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.indigo),
                            ),
                            value: isDarkMode,
                            activeThumbColor: AppTheme.alertRed,
                            activeTrackColor: Colors.white,
                            inactiveThumbColor: isDark ? Colors.grey.shade400 : Colors.grey.shade300,
                            inactiveTrackColor: isDark ? AppTheme.bgDeep : Colors.grey.shade400,
                            onChanged: (value) {
                              AppTheme.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                            },
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 32),
                    SafetyButton.danger(
                      label: 'Cerrar Sesión',
                      icon: Icons.logout_rounded,
                      onPressed: () async {
                        await AuthService.logout();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginView()),
                          (route) => false,
                        );
                      },
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgDeep : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDark ? AppTheme.textSecondary : Colors.grey[700], size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textPrimary : Colors.black87),
                  decoration: InputDecoration(
                    labelText: title,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondary : Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textPrimary : Colors.black87,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
