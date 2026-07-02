import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

// ============================================================================
// SkeletonLoader — Lista de tarjetas "fantasma" con shimmer, para reemplazar
// el CircularProgressIndicator centrado en pantallas que cargan una lista de
// tarjetas (reportes, validaciones, usuarios, solicitudes).
// ============================================================================
// USO:
//   _isLoading ? const SkeletonLoader(count: 4) : ListView.builder(...)
// ============================================================================

class SkeletonLoader extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const SkeletonLoader({
    super.key,
    this.count = 4,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.bgSurface : Colors.grey.shade100;
    final blockColor = isDark ? AppTheme.bgElevated : Colors.grey.shade300;
    final shimmerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.6);

    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderSubtle, width: 1),
              ),
              child: Row(
                children: [
                  _block(width: 44, height: 44, radius: 22, color: blockColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _block(
                          width: double.infinity,
                          height: 14,
                          radius: 6,
                          color: blockColor,
                        ),
                        const SizedBox(height: 10),
                        _block(
                          width: 140,
                          height: 12,
                          radius: 6,
                          color: blockColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1200.ms, color: shimmerColor);
      },
    );
  }

  Widget _block({
    required double width,
    required double height,
    required double radius,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
