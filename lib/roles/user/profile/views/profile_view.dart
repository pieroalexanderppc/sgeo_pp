import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../features/auth/views/login_view.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/widgets/safety_card.dart';
import '../../../../core/widgets/safety_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileView extends StatefulWidget {
  final String? userName;
  final String? userRole;
  final String? userId;
  final VoidCallback? onNavigateToMap;

  const ProfileView({super.key, this.userName, this.userRole, this.userId, this.onNavigateToMap});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
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
    if (widget.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://sgeo-backend-production.up.railway.app/api/usuarios/${widget.userId}',
        ),
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
      debugPrint('Error cargando perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (widget.userId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse(
          'https://sgeo-backend-production.up.railway.app/api/usuarios/${widget.userId}',
        ),
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
            const SnackBar(content: Text('Perfil actualizado con éxito')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar datos')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de red: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarMenuAyuda(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppTheme.borderTactical, width: 0.5),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.textMuted : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Centro de Ayuda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.textPrimary : null,
                  ),
                ),
                const SizedBox(height: 10),
                _buildHelpTile(
                  ctx: ctx,
                  icon: Icons.touch_app,
                  title: 'Cómo reportar un incidente',
                  subtitle: 'Aprende a ubicar un delito en el mapa interactivo.',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    TutorialService.forceStartTutorial('report');
                    if (widget.onNavigateToMap != null) {
                      widget.onNavigateToMap!();
                    }
                  },
                ),
                _buildHelpTile(
                  ctx: ctx,
                  icon: Icons.layers,
                  title: 'Cómo usar los filtros del mapa',
                  subtitle: 'Aprende a configurar qué zonas o reportes ver.',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    TutorialService.forceStartTutorial('filter');
                    if (widget.onNavigateToMap != null) {
                      widget.onNavigateToMap!();
                    }
                  },
                ),
                _buildHelpTile(
                  ctx: ctx,
                  icon: Icons.history,
                  title: 'Cómo revisar el estado de un reporte',
                  subtitle: 'Sigue el estado de un caso en la pestaña Reportes.',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Este tutorial estará disponible pronto.')),
                    );
                  },
                ),
                _buildHelpTile(
                  ctx: ctx,
                  icon: Icons.notifications_active,
                  title: 'Alertas por zonas de riesgo GPS',
                  subtitle: 'Aprende cómo funciona el geofencing automático.',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Este tutorial estará disponible pronto.')),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpTile({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.accentBlue, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? AppTheme.textPrimary : null,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondary : Colors.grey[600],
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? AppTheme.textMuted : Colors.grey,
            size: 20,
          ),
          onTap: onTap,
        ),
        Divider(
          height: 1,
          indent: 70,
          color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Column(
          children: [
            // ── Avatar con glow táctico ──
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppTheme.accentBlue.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: isDark ? AppTheme.accentBlue : const Color(0xFF0061A4),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 500.ms),
            
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              Text(
                _nombre ?? 'Mi Perfil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.textPrimary : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              if (_rol != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _rol!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 28),

            // ── Card de datos personales ──
            SafetyCard(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildProfileField(
                    icon: Icons.person_outline,
                    label: 'Nombre',
                    value: _nombre ?? '-',
                    controller: _nameController,
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200),
                  _buildProfileField(
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    value: (_email == null || _email!.isEmpty) ? 'No especificado' : _email!,
                    controller: _emailController,
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200),
                  _buildProfileField(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: (_telefono == null || _telefono!.isEmpty) ? 'No especificado' : _telefono!,
                    controller: _phoneController,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Botones de edición ──
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: SafetyButton(
                      label: 'Guardar',
                      icon: Icons.save_outlined,
                      onPressed: _saveChanges,
                    ),
                  ),
                ],
              )
            else
              SafetyButton(
                label: 'Editar Perfil',
                icon: Icons.edit_outlined,
                onPressed: () => setState(() => _isEditing = true),
              ),

            const SizedBox(height: 28),

            // ── Toggle de Modo Oscuro/Claro ──
            SafetyCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: EdgeInsets.zero,
              shadowBlur: 0,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.themeNotifier,
                builder: (context, currentMode, child) {
                  final isDarkMode = currentMode == ThemeMode.dark;
                  return SwitchListTile(
                    title: Text(
                      'Modo Oscuro',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textPrimary : null,
                      ),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppTheme.accentBlue.withValues(alpha: 0.12)
                            : Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: isDarkMode ? AppTheme.accentBlueLight : Colors.amber.shade700,
                        size: 22,
                      ),
                    ),
                    value: isDarkMode,
                    onChanged: (value) {
                      AppTheme.themeNotifier.value = value
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ── Botón de Ayuda / Tutorial ──
            SafetyButton.outline(
              label: 'Centro de Ayuda',
              icon: Icons.help_outline,
              onPressed: () => _mostrarMenuAyuda(context),
            ),

            const SizedBox(height: 40),

            // ── Cerrar Sesión ──
            SafetyButton.danger(
              label: 'Cerrar Sesión',
              icon: Icons.logout,
              onPressed: () async {
                // Cerrar sesión borrando los datos cacheados
                await AuthService.logout();
                if (!context.mounted) return;
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
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgDeep : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? AppTheme.textSecondary : Colors.grey[600], size: 22),
      ),
      title: _isEditing
          ? TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
          : Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textSecondary : Colors.grey[600],
              ),
            ),
      subtitle: _isEditing
          ? null
          : Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textPrimary : null,
              ),
            ),
    );
  }
}
