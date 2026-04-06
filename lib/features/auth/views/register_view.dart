import 'package:flutter/material.dart';
import 'package:sgeo_pp/core/services/auth_service.dart';

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
    if (strength == 0) {
      return Colors.grey;
    }
    if (strength <= 1) {
      return Colors.red;
    }
    if (strength == 2) {
      return Colors.orange;
    }
    if (strength == 3) {
      return Colors.yellow;
    }
    return Colors.green;
  }

  String _getStrengthText(int strength) {
    if (strength == 0) {
      return '';
    }
    if (strength <= 1) {
      return 'Bajo';
    }
    if (strength == 2) {
      return 'Medio';
    }
    return 'Alto';
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

    final partesEmail = email.split('@');
    final prefijoEmail = partesEmail.first;
    final dominioEmail = partesEmail.last.toLowerCase();

    if (prefijoEmail.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor ingresa un correo electrónico válido',
          ),
        ),
      );
      return;
    }

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
            title: const Text('Registro en verificación'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Crea tu cuenta'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add_alt_1, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 8),
              const Text(
                'Mínimo 8 caracteres. No se aceptan: _ - | { } & *',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            _calculatePasswordStrength(
                              _passwordController.text,
                            ) /
                            4,
                        color: _getStrengthColor(
                          _calculatePasswordStrength(_passwordController.text),
                        ),
                        backgroundColor: Colors.grey[300],
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStrengthText(
                      _calculatePasswordStrength(_passwordController.text),
                    ),
                    style: TextStyle(
                      color: _getStrengthColor(
                        _calculatePasswordStrength(_passwordController.text),
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  filled: true,
                ),
                obscureText: _obscureConfirmPassword,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('¿Eres efectivo policial?'),
                value: _isPolicial,
                onChanged: (bool? value) {
                  setState(() {
                    _isPolicial = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _register,
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
