import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sgeo_pp/roles/user/home/views/home_view.dart';
import 'package:sgeo_pp/roles/police/home/views/home_view.dart';
import 'package:sgeo_pp/roles/admin/home/views/home_view.dart';
import 'package:sgeo_pp/features/auth/views/register_view.dart';
import 'package:sgeo_pp/core/services/auth_service.dart';
import 'package:sgeo_pp/core/theme/app_theme.dart';
import 'package:sgeo_pp/core/widgets/safety_layout.dart';
import 'package:sgeo_pp/core/widgets/safety_card.dart';
import 'package:sgeo_pp/core/widgets/safety_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      final userData = result['data']['usuario'];
      final userRole = userData['rol'] ?? 'ciudadano';

      // 🔔 Suscribir al topic correcto en Firebase según el rol
      if (userRole == 'policia') {
        await FirebaseMessaging.instance.subscribeToTopic('alertas_policiales');
        await FirebaseMessaging.instance.unsubscribeFromTopic('alertas_ciudadanos');
      } else {
        // En un futuro podrías sacar el distrito de userData['distrito']
        await FirebaseMessaging.instance.subscribeToTopic('alertas_ciudadanos');
        await FirebaseMessaging.instance.unsubscribeFromTopic('alertas_policiales');
      }
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            if (userRole == 'policia') {
              return PoliceHomeView(
                userRole: userRole,
                userName: userData['nombre'] ?? '',
                userId: userData['id'] ?? userData['_id'] ?? '',
              );
            } else if (userRole == 'admin' || userRole == 'administrador') {
              return AdminHomeView(
                userRole: userRole,
                userName: userData['nombre'] ?? '',
                userId: userData['id'] ?? userData['_id'] ?? '',
              );
            } else {
              return HomeView(
                userRole: userRole,
                userName: userData['nombre'] ?? '',
                userId: userData['id'] ?? userData['_id'] ?? '',
              );
            }
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafetyLayout(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Logo / Ícono táctico ──
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentBlue.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 56,
                  color: isDark ? AppTheme.accentBlue : const Color(0xFF0061A4),
                ),
              )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 600.ms),

              const SizedBox(height: 20),

              // ── Título ──
              Text(
                'Bienvenido a SGEO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppTheme.textPrimary : null,
                ),
              )
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 6),

              // ── Subtítulo ──
              Text(
                'Sistema de Geolocalización de Inseguridad',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                  letterSpacing: 0.3,
                ),
              )
                .animate()
                .fadeIn(delay: 350.ms, duration: 500.ms),

              const SizedBox(height: 40),

              // ── Card del formulario ──
              SafetyCard(
                glassEffect: isDark,
                padding: const EdgeInsets.all(24),
                animateEntry: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Encabezado del formulario ──
                    Text(
                      'Inicia Sesión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textPrimary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresa tus credenciales para acceder',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Campo: Email ──
                    // El InputDecoration hereda automáticamente del inputDecorationTheme
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'correo@ejemplo.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // ── Campo: Contraseña ──
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                    ),

                    const SizedBox(height: 8),

                    // ── Olvidé contraseña (alineado a la derecha) ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMuted : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Botón de Login ──
                    SafetyButton(
                      label: _isLoading ? 'Ingresando...' : 'Iniciar Sesión',
                      icon: _isLoading ? null : Icons.login,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _login,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Link a Registro ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterView(),
                        ),
                      );
                    },
                    child: Text(
                      'Regístrate aquí',
                      style: TextStyle(
                        color: isDark ? AppTheme.accentBlueLight : const Color(0xFF0061A4),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )
                .animate()
                .fadeIn(delay: 600.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
