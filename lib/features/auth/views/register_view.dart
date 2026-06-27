// Rediseño visual v2: selector de rol como 2 tarjetas (antes Switch+card), aviso
// policial con AnimatedSwitcher, fondo con gradiente diagonal, boton primario accentCyan.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sgeo_pp/core/services/auth_service.dart';
import 'package:sgeo_pp/core/theme/app_theme.dart';
import 'package:sgeo_pp/core/widgets/safety_layout.dart';
import 'package:sgeo_pp/core/widgets/safety_card.dart';
import 'package:sgeo_pp/core/widgets/safety_button.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPolicial = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return 0;
    }

    int strength = 0;
    if (password.length >= 8) {
      strength++;
    } // Min 8 chars
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      strength++;
    } // Has uppercase
    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
    } // Has numbers
    if (RegExp(r'[!@#\$~]').hasMatch(password)) {
      strength++;
    } // Has special chars (removed & and * as they are not allowed)

    return strength;
  }

  Color _getStrengthColor(int strength) {
    if (strength == 0) return AppTheme.textMuted;
    if (strength <= 1) return AppTheme.alertRed;
    if (strength == 2) return AppTheme.alertAmber;
    if (strength == 3) return const Color(0xFFCDDC39);
    return AppTheme.successGreen;
  }

  String _getStrengthText(int strength) {
    if (strength == 0) return '';
    if (strength <= 1) return 'Débil';
    if (strength == 2) return 'Medio';
    if (strength == 3) return 'Bueno';
    return 'Fuerte';
  }

  Future<void> _register() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (nombre.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (nombre.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de usuario es demasiado corto'),
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un correo electrónico válido'),
        ),
      );
      return;
    }

    final dominioEmail = email.split('@').last.toLowerCase();

    final dominiosPermitidos = [
      'gmail.com',
      'hotmail.com',
      'outlook.com',
      'yahoo.com',
      'live.com',
    ];

    if (!dominiosPermitidos.contains(dominioEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo se permiten correos de Google, Microsoft o Yahoo (@gmail.com, @hotmail.com, etc.)',
          ),
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 8 caracteres'),
        ),
      );
      return;
    }

    if (RegExp(r'[_|\-{}&*]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La contraseña contiene caracteres no permitidos (_ - | { } & *)',
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final rol = _isPolicial ? 'policia' : 'ciudadano';
    final isActive = !_isPolicial;

    final result = await AuthService.register(
      nombre,
      email,
      password,
      rol: rol,
      isActive: isActive,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      if (_isPolicial) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.verified_user, color: AppTheme.alertAmber, size: 24),
                const SizedBox(width: 10),
                const Expanded(child: Text('Registro en verificación')),
              ],
            ),
            content: const Text(
              'Te enviaremos un correo donde debes brindar tus datos para verificar si efectivamente eres policía. '
              'El estado de tu cuenta estará desactivado y no podrás iniciar sesión hasta que el administrador la haya activado.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada exitosamente!')),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordStrength = _calculatePasswordStrength(
      _passwordController.text,
    );
    final strengthColor = _getStrengthColor(passwordStrength);

    return SafetyLayout(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? AppTheme.textPrimary : null,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.bgDeep, Color(0xFF0D1424)],
                )
              : null,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Ícono de registro ──
                Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentCyan.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1,
                        size: 44,
                        color: isDark
                            ? AppTheme.accentCyan
                            : const Color(0xFF0061A4),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                    ),

                const SizedBox(height: 24),

                // ── Card del formulario ──
                SafetyCard(
                      glassEffect: isDark,
                      padding: const EdgeInsets.all(24),
                      borderColor: AppTheme.borderSubtle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Encabezado ──
                          Text(
                            'Datos de Registro',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textPrimary : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completa los campos para crear tu cuenta',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Campo: Nombre ──
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de usuario',
                              prefixIcon: Icon(Icons.person_outline),
                              hintText: 'Tu nombre visible',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Campo: Email ──
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
                            onChanged: (value) => setState(() {}),
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
                          const SizedBox(height: 10),

                          // ── Indicador de fortaleza ──
                          Text(
                            'Mínimo 8 caracteres. No se aceptan: _ - | { } & *',
                            style: TextStyle(
                              color: isDark ? AppTheme.textMuted : Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: passwordStrength / 4,
                                    color: strengthColor,
                                    backgroundColor: isDark
                                        ? AppTheme.bgDeep
                                        : Colors.grey[300],
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: strengthColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                child: Text(_getStrengthText(passwordStrength)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Campo: Confirmar Contraseña ──
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirmar Contraseña',
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                          ),
                          const SizedBox(height: 16),

                          // ── Selector de rol: 2 tarjetas seleccionables ──
                          Text(
                            'Tipo de cuenta',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textMuted
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleCard(
                                  label: 'Ciudadano',
                                  icon: Icons.person_outline,
                                  selected: !_isPolicial,
                                  isDark: isDark,
                                  onTap: () =>
                                      setState(() => _isPolicial = false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRoleCard(
                                  label: 'Policía',
                                  icon: Icons.local_police_outlined,
                                  selected: _isPolicial,
                                  isDark: isDark,
                                  onTap: () =>
                                      setState(() => _isPolicial = true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Aviso informativo (solo si se elige Policía) ──
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isPolicial
                                ? Container(
                                    key: const ValueKey('aviso-policial'),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.alertAmber.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.alertAmber,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: AppTheme.alertAmber,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Tu cuenta será revisada por el administrador antes de activarse',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.alertAmber,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('sin-aviso'),
                                  ),
                          ),

                          const SizedBox(height: 28),

                          // ── Botón de Registro ──
                          SafetyButton(
                            label: _isLoading
                                ? 'Registrando...'
                                : 'Crear Cuenta',
                            icon: _isLoading ? null : Icons.how_to_reg,
                            isLoading: _isLoading,
                            variant: ButtonVariant.primary,
                            onPressed: _isLoading ? null : _register,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tarjeta seleccionable del rol (Ciudadano | Policía)
  Widget _buildRoleCard({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final color = selected ? AppTheme.accentCyan : AppTheme.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentCyan.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accentCyan : AppTheme.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppTheme.accentCyan
                    : (isDark ? AppTheme.textSecondary : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
