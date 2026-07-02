import 'package:flutter/material.dart';

// ============================================================================
// NavBounceIcon — Pulso de escala (1.0 -> 1.18 -> 1.0) al seleccionar un tab
// ============================================================================
// Envuelve el icono de un BottomNavigationBarItem; no reemplaza ni envuelve el
// BottomNavigationBar en si (sigue siendo el widget nativo de Flutter).
// USO:
//   icon: NavBounceIcon(isSelected: _currentIndex == 0, child: Icon(Icons.map)),
// ============================================================================

class NavBounceIcon extends StatefulWidget {
  final bool isSelected;
  final Widget child;

  const NavBounceIcon({
    super.key,
    required this.isSelected,
    required this.child,
  });

  @override
  State<NavBounceIcon> createState() => _NavBounceIconState();
}

class _NavBounceIconState extends State<NavBounceIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.18,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(NavBounceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
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
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
