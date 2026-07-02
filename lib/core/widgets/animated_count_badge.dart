import 'package:flutter/material.dart';

// ============================================================================
// AnimatedCountBadge — Icono + Badge numerico con scale-pop cuando el conteo
// cambia (1.0 -> 1.35 -> 1.0). Reemplaza los 3 "_buildBadgedIcon" casi
// identicos que existian en los nav bars de ciudadano/policia/admin.
// ============================================================================
// USO:
//   AnimatedCountBadge(icon: Icons.notifications, count: unread)
//   AnimatedCountBadge(icon: Icons.fact_check, count: pendientes, badgeColor: AppTheme.alertAmber)
// ============================================================================

class AnimatedCountBadge extends StatefulWidget {
  final IconData icon;
  final int count;
  final Color? badgeColor;

  const AnimatedCountBadge({
    super.key,
    required this.icon,
    required this.count,
    this.badgeColor,
  });

  @override
  State<AnimatedCountBadge> createState() => _AnimatedCountBadgeState();
}

class _AnimatedCountBadgeState extends State<AnimatedCountBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedCountBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count && widget.count > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return Icon(widget.icon);
    return ScaleTransition(
      scale: _scale,
      child: Badge(
        backgroundColor: widget.badgeColor,
        label: Text(widget.count > 9 ? '9+' : widget.count.toString()),
        child: Icon(widget.icon),
      ),
    );
  }
}
