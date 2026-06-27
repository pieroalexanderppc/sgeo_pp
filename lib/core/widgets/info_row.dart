import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// InfoRow — Fila de dato etiqueta/valor para perfiles y detalles
// ============================================================================
// Nota de nombrado: el plan original lo llamaba "DataRow", pero ese nombre ya
// existe en package:flutter/material.dart (lo usa DataTable) y colisionaría
// con ese import en cualquier pantalla que tuviera ambos. Se llama InfoRow.
//
// USO:
//   InfoRow(label: 'DNI', value: '12345678', icon: Icons.badge)
// ============================================================================

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgElevated : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? AppTheme.textSecondary : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMuted : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
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
      ),
    );
  }
}
