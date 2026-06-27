import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// RoleBadge — Badge de rol reutilizable (ciudadano/policia/admin)
// ============================================================================
// USO:
//   RoleBadge(role: 'policia')
// ============================================================================

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  static Color colorFor(String role) {
    switch (role.toLowerCase()) {
      case 'policia':
        return AppTheme.alertAmber;
      case 'admin':
      case 'administrador':
        return AppTheme.accentCyan;
      case 'ciudadano':
      default:
        return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
