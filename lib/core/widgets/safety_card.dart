import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// SafetyCard — Tarjeta táctica con Glassmorphism opaco y bordes sutiles
// ============================================================================
// Reemplazo premium del Card() estándar de Material.
// Características:
//  • Fondo de superficie #161B22 con borde blanco al 10% (0.5px)
//  • Sombra suave difusa (no Material elevation)
//  • BorderRadius de 20.0 (configurable)
//  • Efecto glassmorphism opcional con BackdropFilter
//  • Animación de entrada automática (fade + scale) al montarse
//
// USO:
//   SafetyCard(
//     child: ListTile(title: Text('Reporte #123')),
//   )
//
//   SafetyCard(
//     glassEffect: true,   // Activa el blur del glassmorphism
//     accentColor: AppTheme.alertRed,  // Borde lateral de alerta
//     child: MiContenido(),
//   )
// ============================================================================

class SafetyCard extends StatefulWidget {
  /// Contenido interno de la tarjeta.
  final Widget child;

  /// Padding interno. Por defecto: 16 en todos los lados.
  final EdgeInsetsGeometry padding;

  /// Margen externo.
  final EdgeInsetsGeometry margin;

  /// Radio de borde. Por defecto: 20.0 (geometría táctica).
  final double borderRadius;

  /// Color de fondo. Por defecto: AppTheme.bgSurface (#161B22).
  final Color? backgroundColor;

  /// Color del borde. Por defecto: blanco al 10%.
  final Color borderColor;

  /// Grosor del borde. Por defecto: 0.5.
  final double borderWidth;

  /// Si es `true`, aplica un efecto de glassmorphism con BackdropFilter.
  final bool glassEffect;

  /// Intensidad del blur del glassmorphism (solo si glassEffect = true).
  final double blurIntensity;

  /// Color de acento lateral (barra de 3px a la izquierda).
  /// Si es null, no se muestra la barra de acento.
  final Color? accentColor;

  /// Ancho de la barra de acento lateral.
  final double accentWidth;

  /// Callback al presionar la tarjeta. Si es null, la tarjeta no es interactiva.
  final VoidCallback? onTap;

  /// Si es `true`, anima la entrada de la tarjeta con fade + scale.
  final bool animateEntry;

  /// Duración de la animación de entrada.
  final Duration animationDuration;

  /// Elevación de sombra suave. 0 = sin sombra.
  final double shadowBlur;

  const SafetyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.borderRadius = 20.0,
    this.backgroundColor,
    this.borderColor = AppTheme.borderTactical,
    this.borderWidth = 0.5,
    this.glassEffect = false,
    this.blurIntensity = 10.0,
    this.accentColor,
    this.accentWidth = 3.0,
    this.onTap,
    this.animateEntry = true,
    this.animationDuration = const Duration(milliseconds: 350),
    this.shadowBlur = 12.0,
  });

  @override
  State<SafetyCard> createState() => _SafetyCardState();
}

class _SafetyCardState extends State<SafetyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  // Para la micro-interacción de tap
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _scaleAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    if (widget.animateEntry) {
      // Pequeño delay aleatorio para efecto escalonado en listas
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted) _entryController.forward();
      });
    } else {
      _entryController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? AppTheme.bgSurface : Theme.of(context).cardColor);

    // ── Construir el contenido con padding ──
    Widget content = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    // ── Barra de acento lateral (si existe) ──
    if (widget.accentColor != null) {
      content = Row(
        children: [
          Container(
            width: widget.accentWidth,
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.borderRadius),
                bottomLeft: Radius.circular(widget.borderRadius),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    // ── Contenedor principal (forma + borde + sombra) ──
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      transform: Matrix4.diagonal3Values(
        _isPressed ? 0.98 : 1.0,
        _isPressed ? 0.98 : 1.0,
        1.0,
      ),
      transformAlignment: Alignment.center,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.glassEffect ? bgColor.withValues(alpha: 0.7) : bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
        boxShadow: widget.shadowBlur > 0 && isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: widget.shadowBlur,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ]
            : widget.shadowBlur > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: widget.shadowBlur,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
      ),
      child: widget.glassEffect && isDark
          ? ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blurIntensity,
                  sigmaY: widget.blurIntensity,
                ),
                child: content,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: content,
            ),
    );

    // ── Hacer interactivo si hay onTap ──
    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: card,
      );
    }

    // ── Animación de entrada ──
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: card,
      ),
    );
  }
}
