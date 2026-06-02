import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// SafetyScoreFab — Botón flotante circular compacto de Safety Score
// ============================================================================
// Widget compacto que muestra el Safety Score como un icono circular con un
// anillo de progreso alrededor. Al tocar, expande un tooltip estilizado
// con los detalles del score.
//
// USO:
//   SafetyScoreFab(
//     score: 54,
//     nivel: 'precaucion',
//     mensaje: 'Precaución recomendada',
//     onExpandInsights: () { ... },
//   )
// ============================================================================

class SafetyScoreFab extends StatefulWidget {
  final double score;
  final String nivel;
  final String mensaje;
  final VoidCallback? onExpandInsights;

  /// Diámetro total del botón (icono + anillo)
  final double diameter;

  const SafetyScoreFab({
    super.key,
    required this.score,
    required this.nivel,
    this.mensaje = '',
    this.onExpandInsights,
    this.diameter = 52,
  });

  @override
  State<SafetyScoreFab> createState() => _SafetyScoreFabState();
}

class _SafetyScoreFabState extends State<SafetyScoreFab>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late AnimationController _tooltipController;
  late Animation<double> _tooltipOpacity;
  late Animation<Offset> _tooltipSlide;

  bool _showTooltip = false;

  @override
  void initState() {
    super.initState();

    // Animación del progreso del anillo
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();

    // Animación del tooltip
    _tooltipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tooltipOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tooltipController, curve: Curves.easeOut),
    );
    _tooltipSlide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _tooltipController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(SafetyScoreFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.score / 100,
      ).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeOutCubic,
        ),
      );
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _tooltipController.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successGreen;
    if (score >= 50) return AppTheme.alertAmber;
    return AppTheme.alertRed;
  }

  void _toggleTooltip() {
    setState(() => _showTooltip = !_showTooltip);
    if (_showTooltip) {
      _tooltipController.forward();
      // Auto-ocultar después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showTooltip) {
          _hideTooltip();
        }
      });
    } else {
      _tooltipController.reverse();
    }
  }

  void _hideTooltip() {
    if (!mounted) return;
    _tooltipController.reverse().then((_) {
      if (mounted) setState(() => _showTooltip = false);
    });
  }

  String _defaultMessage(double score) {
    if (score >= 80) return 'Zona segura';
    if (score >= 50) return 'Precaución recomendada';
    return 'Alto riesgo';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(widget.score);
    final mensaje = widget.mensaje.isNotEmpty
        ? widget.mensaje.replaceAll(' — mantente alerta', '')
        : _defaultMessage(widget.score);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Tooltip Expandible (a la izquierda del botón) ──
        if (_showTooltip)
          AnimatedBuilder(
            animation: _tooltipController,
            builder: (context, child) {
              return SlideTransition(
                position: _tooltipSlide,
                child: FadeTransition(
                  opacity: _tooltipOpacity,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 200),
              decoration: BoxDecoration(
                color: const Color(0xFF141619),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scoreColor.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SCORE: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    widget.score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  Flexible(
                    child: Text(
                      mensaje,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scoreColor.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Botón Circular Principal ──
        GestureDetector(
          onTap: _toggleTooltip,
          onLongPress: () {
            _toggleTooltip();
            widget.onExpandInsights?.call();
          },
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                width: widget.diameter,
                height: widget.diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF141619),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _RingProgressPainter(
                    progress: _progressAnimation.value,
                    color: scoreColor,
                    strokeWidth: 3.5,
                  ),
                  child: Center(
                    child: Container(
                      width: widget.diameter * 0.68,
                      height: widget.diameter * 0.68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        color: scoreColor,
                        size: widget.diameter * 0.38,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Painter: Anillo circular de progreso
// ═══════════════════════════════════════════════════════════════════════════

class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2) - 2;
    const startAngle = -math.pi / 2; // Empieza en la posición 12 del reloj
    const sweepTotal = math.pi * 2;
    final sweepAngle = sweepTotal * progress.clamp(0.0, 1.0);

    // Fondo del anillo (track)
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Progreso del anillo
    if (sweepAngle > 0) {
      final progressPaint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [color.withValues(alpha: 0.5), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // Punto final (dot indicator)
      final endAngle = startAngle + sweepAngle;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);

      // Glow
      canvas.drawCircle(
        Offset(dotX, dotY),
        5,
        Paint()..color = color.withValues(alpha: 0.3),
      );

      // Dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        3,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        1.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
