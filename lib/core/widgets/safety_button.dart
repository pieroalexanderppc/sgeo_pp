import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// SafetyButton — Botón táctico con micro-interacciones de escala y brillo
// ============================================================================
// Reemplazo premium de ElevatedButton con:
//  • Transformación de escala al presionar (0.95x)
//  • Efecto de brillo sutil en hover/press
//  • Soporte para íconos con spacing táctico
//  • Variante outline (borde táctico sin relleno)
//  • Loading state integrado con spinner
//
// USO:
//   SafetyButton(
//     label: 'Enviar Reporte',
//     icon: Icons.send,
//     onPressed: () => enviarReporte(),
//   )
//
//   SafetyButton.outline(
//     label: 'Cancelar',
//     onPressed: () => Navigator.pop(context),
//   )
//
//   SafetyButton(
//     label: 'Procesando...',
//     isLoading: true,
//     onPressed: null,
//   )
// ============================================================================

class SafetyButton extends StatefulWidget {
  /// Texto del botón.
  final String label;

  /// Ícono opcional a la izquierda del label.
  final IconData? icon;

  /// Callback al presionar. Si es null, el botón queda deshabilitado.
  final VoidCallback? onPressed;

  /// Color de fondo. Por defecto: accentBlue.
  final Color? backgroundColor;

  /// Color del texto e ícono. Por defecto: blanco.
  final Color? foregroundColor;

  /// Si es `true`, muestra un CircularProgressIndicator en lugar del contenido.
  final bool isLoading;

  /// Si es `true`, renderiza como botón outline (borde táctico, fondo transparente).
  final bool isOutline;

  /// Si es `true`, renderiza como botón de peligro (rojo).
  final bool isDanger;

  /// Padding interno.
  final EdgeInsetsGeometry padding;

  /// Radio del borde.
  final double borderRadius;

  /// Si el botón ocupa todo el ancho disponible.
  final bool expand;

  /// Tamaño del texto.
  final double fontSize;

  const SafetyButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isOutline = false,
    this.isDanger = false,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    this.borderRadius = 12.0,
    this.expand = true,
    this.fontSize = 16,
  });

  /// Constructor nombrado para variante outline.
  const SafetyButton.outline({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isDanger = false,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    this.borderRadius = 12.0,
    this.expand = true,
    this.fontSize = 16,
  }) : isOutline = true;

  /// Constructor nombrado para variante de peligro.
  const SafetyButton.danger({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isOutline = false,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    this.borderRadius = 12.0,
    this.expand = true,
    this.fontSize = 16,
  }) : isDanger = true;

  @override
  State<SafetyButton> createState() => _SafetyButtonState();
}

class _SafetyButtonState extends State<SafetyButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  // Colores resueltos según variante
  Color _resolveBackground(bool isDark) {
    if (widget.isOutline) return Colors.transparent;
    if (widget.isDanger) return widget.backgroundColor ?? AppTheme.alertRed;
    return widget.backgroundColor ?? AppTheme.accentBlue;
  }

  Color _resolveForeground(bool isDark) {
    if (widget.isOutline) {
      if (widget.isDanger) return AppTheme.alertRed;
      return widget.foregroundColor ?? AppTheme.accentBlueLight;
    }
    return widget.foregroundColor ?? Colors.white;
  }

  Color _resolveBorderColor(bool isDark) {
    if (widget.isOutline) {
      if (widget.isDanger) return AppTheme.alertRed.withValues(alpha: 0.5);
      return AppTheme.borderTactical;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final bgColor = _resolveBackground(isDark);
    final fgColor = _resolveForeground(isDark);
    final borderColor = _resolveBorderColor(isDark);

    // ── Contenido del botón (label + ícono o spinner) ──
    Widget content;
    if (widget.isLoading) {
      content = Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
          ),
        ),
      );
    } else {
      final textWidget = Text(
        widget.label,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: isDisabled ? fgColor.withValues(alpha: 0.5) : fgColor,
        ),
      );

      if (widget.icon != null) {
        content = Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: isDisabled ? fgColor.withValues(alpha: 0.5) : fgColor,
            ),
            const SizedBox(width: 10),
            textWidget,
          ],
        );
      } else {
        content = Center(child: textWidget);
      }
    }

    // ── Botón con AnimatedContainer para micro-interacción ──
    Widget button = GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            },
      onTapCancel: isDisabled
          ? null
          : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        transform: Matrix4.diagonal3Values(
          _isPressed ? 0.96 : 1.0,
          _isPressed ? 0.96 : 1.0,
          1.0,
        ),
        transformAlignment: Alignment.center,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: isDisabled
              ? bgColor.withValues(alpha: 0.4)
              : _isPressed
                  ? bgColor.withValues(alpha: 0.85)
                  : bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isDisabled ? borderColor.withValues(alpha: 0.3) : borderColor,
            width: widget.isOutline ? 0.5 : 0,
          ),
          // Glow sutil al presionar en dark mode
          boxShadow: _isPressed && isDark && !widget.isOutline
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: content,
      ),
    );

    if (widget.expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
