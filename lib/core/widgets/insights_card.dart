import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// InsightsCard — Tarjeta de insight predictivo Premium Tactical Dark
// ============================================================================
// Muestra un insight generado por el motor predictivo con ícono, mensaje,
// severidad codificada por color y animación de entrada escalonada.
//
// USO:
//   InsightsCard(
//     insights: [
//       {'tipo': 'temporal', 'icono': 'schedule', 'mensaje': '...', 'severidad': 'warning'},
//     ],
//   )
// ============================================================================

class InsightsCard extends StatelessWidget {
  final List<Map<String, dynamic>> insights;

  const InsightsCard({super.key, required this.insights});

  IconData _resolveIcon(String? iconName) {
    switch (iconName) {
      case 'schedule': return Icons.schedule_rounded;
      case 'verified_user': return Icons.verified_user_rounded;
      case 'lightbulb': return Icons.lightbulb_rounded;
      case 'trending_up': return Icons.trending_up_rounded;
      case 'trending_down': return Icons.trending_down_rounded;
      case 'warning': return Icons.warning_rounded;
      case 'event': return Icons.event_rounded;
      default: return Icons.info_rounded;
    }
  }

  Color _severityColor(String? severidad) {
    switch (severidad) {
      case 'danger': return AppTheme.alertRed;
      case 'warning': return AppTheme.alertAmber;
      case 'info': return AppTheme.accentBlue;
      default: return AppTheme.textSecondary;
    }
  }

  Color _severityBg(String? severidad) {
    switch (severidad) {
      case 'danger': return AppTheme.alertRedBg;
      case 'warning': return AppTheme.alertAmber.withValues(alpha: 0.15);
      case 'info': return AppTheme.accentBlue.withValues(alpha: 0.12);
      default: return AppTheme.bgElevated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderTactical, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.accentBlueLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Analizando patrones de seguridad...',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderTactical, width: 0.5),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -2)]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'INSIGHTS DE SEGURIDAD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Insights list
          ...List.generate(insights.length, (index) {
            final insight = insights[index];
            final color = _severityColor(insight['severidad']);
            final bgColor = _severityBg(insight['severidad']);
            final icon = _resolveIcon(insight['icono']);

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight['mensaje'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.textPrimary : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
