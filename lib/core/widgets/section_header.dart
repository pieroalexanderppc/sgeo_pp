import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// SectionHeader — Encabezado de sección reutilizable (título + subtítulo + acción)
// ============================================================================
// USO:
//   SectionHeader(title: 'Validaciones', subtitle: '3 pendientes')
//   SectionHeader(title: 'Reportes', action: IconButton(...))
// ============================================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimary : Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textMuted : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}
