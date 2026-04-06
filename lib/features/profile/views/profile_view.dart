import 'package:flutter/material.dart';
import '../../auth/views/login_view.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileView extends StatefulWidget {
  final String? userName;
  final String? userRole;
  final String? userId;

  const ProfileView({super.key, this.userName, this.userRole, this.userId});

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              Text(
                _nombre ?? 'Mi Perfil',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_rol != null)
                Text(
                  _rol!.toUpperCase(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
            ],

            const SizedBox(height: 30),

            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: _isEditing
                          ? TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre Completo',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          : const Text('Nombre'),
                      subtitle: _isEditing ? null : Text(_nombre ?? '-'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: _isEditing
                          ? TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo Electrónico',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          : const Text('Correo'),
                      subtitle: _isEditing
                          ? null
                          : Text(
                              (_email == null || _email!.isEmpty)
                                  ? 'No especificado'
                                  : _email!,
                            ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: _isEditing
                          ? TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          : const Text('Teléfono'),
                      subtitle: _isEditing
                          ? null
                          : Text(
                              (_telefono == null || _telefono!.isEmpty)
                                  ? 'No especificado'
                                  : _telefono!,
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text = _nombre ?? '';
                          _emailController.text = _email ?? '';
                          _phoneController.text = _telefono ?? '';
                        });
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saveChanges,
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
                label: const Text('Editar Perfil'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Toggle de Modo Oscuro/Claro
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.themeNotifier,
              builder: (context, currentMode, child) {
                final isDark = currentMode == ThemeMode.dark;
                return SwitchListTile(
                  title: const Text(
                    'Modo Oscuro',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  value: isDark,
                  onChanged: (value) {
                    AppTheme.themeNotifier.value = value
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(context).cardColor,
                );
              },
            ),

            const SizedBox(height: 40),
            ElevatedButton.icon(
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
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
