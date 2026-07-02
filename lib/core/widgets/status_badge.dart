import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// StatusBadge — Reemplaza los chips de estado armados a mano en cada pantalla
// ============================================================================
// USO:
//   StatusBadge(status: 'pendiente')
//   StatusBadge(status: 'confirmado', label: 'CONFIRMADO HOY')
// ============================================================================

class StatusBadge extends StatelessWidget {
  final String status;

  /// Texto a mostrar. Si es null, se usa `status` en mayúsculas.
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  static Color colorFor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return AppTheme.alertAmber;
      case 'confirmado':
        return AppTheme.successGreen;
      case 'rechazado':
        return AppTheme.alertRed;
      case 'aprobado':
        return AppTheme.accentCyan;
      case 'activo':
        return AppTheme.successGreen;
      case 'suspendido':
        return AppTheme.alertRed;
      case 'agrupado':
        return AppTheme.accentBlue;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    final text = (label ?? status).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
