import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// SafetyLayout — Wrapper de Layout Maestro con fondo táctico y animación
// ============================================================================
// Envuelve el Scaffold de cualquier pantalla para garantizar:
// 1. Fondo con RadialGradient sutil (glow táctico desde el centro)
// 2. Animación de entrada suave (FadeIn + SlideUp) con 400ms de duración
// 3. Consistencia visual global sin modificar la lógica de cada pantalla
//
// USO:
//   SafetyLayout(
//     appBar: AppBar(title: Text('Mi Pantalla')),
//     body: MiContenido(),
//     bottomNavigationBar: MiNavBar(),
//   )
// ============================================================================

class SafetyLayout extends StatefulWidget {
  /// El cuerpo principal de la pantalla.
  final Widget body;

  /// AppBar opcional. Se propaga al Scaffold interno.
  final PreferredSizeWidget? appBar;

  /// BottomNavigationBar opcional.
  final Widget? bottomNavigationBar;

  /// FloatingActionButton opcional.
  final Widget? floatingActionButton;

  /// Ubicación del FAB.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Si es `false`, desactiva la animación de entrada (útil para tabs internos).
  final bool animate;

  /// Duración de la animación de entrada.
  final Duration animationDuration;

  /// Si es `true`, aplica el gradiente radial de fondo táctico.
  /// Desactivar en pantallas donde el mapa ocupa todo el fondo.
  final bool showGradientBackground;

  /// Drawer opcional (menú lateral).
  final Widget? drawer;

  /// Si la pantalla debe extender el body detrás del AppBar.
  final bool extendBodyBehindAppBar;

  /// Permite controlar si el body debe redimensionarse para evitar el teclado.
  final bool? resizeToAvoidBottomInset;

  const SafetyLayout({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 400),
    this.showGradientBackground = true,
    this.drawer,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
  });

  @override
  State<SafetyLayout> createState() => _SafetyLayoutState();
}

class _SafetyLayoutState extends State<SafetyLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03), // Micro-slide sutil (3% hacia arriba)
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _animController.forward();
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget scaffoldBody = widget.body;

    // Aplicar el fondo con gradiente radial táctico solo en modo oscuro
    if (widget.showGradientBackground && isDark) {
      scaffoldBody = DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3), // Ligeramente arriba del centro
            radius: 1.2,
            colors: [
              AppTheme.bgGlowCenter,  // Glow azulado sutil en el centro
              AppTheme.bgGlowEdge,    // Se desvanece al fondo profundo
            ],
            stops: [0.0, 0.7],
          ),
        ),
        child: scaffoldBody,
      );
    }

    // Envolver en animación de entrada
    Widget animatedBody = FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: scaffoldBody,
      ),
    );

    return Scaffold(
      appBar: widget.appBar,
      body: animatedBody,
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      drawer: widget.drawer,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
    );
  }
}
