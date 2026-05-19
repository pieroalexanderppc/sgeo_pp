import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// SafetyScoreGauge — Medidor circular de Safety Score Premium Tactical Dark
// ============================================================================
// Widget animado que muestra el Safety Score (0-100) como un arco circular
// con colores adaptativos (verde/amarillo/rojo), glow dinámico y animación
// de entrada suave. Integrado al design system existente.
//
// USO:
//   SafetyScoreGauge(
//     score: 78.5,
//     nivel: 'precaucion',
//     turno: 'noche',
//     mensaje: 'Precaución recomendada',
//   )
// ============================================================================

class SafetyScoreGauge extends StatefulWidget {
  final double score;
  final String nivel;
  final String turno;
  final String mensaje;
  final double size;

  const SafetyScoreGauge({
    super.key,
    required this.score,
    required this.nivel,
    this.turno = '',
    this.mensaje = '',
    this.size = 140,
  });

  @override
  State<SafetyScoreGauge> createState() => _SafetyScoreGaugeState();
}

class _SafetyScoreGaugeState extends State<SafetyScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SafetyScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = Tween<double>(
        begin: _scoreAnimation.value,
        end: widget.score,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successGreen;
    if (score >= 50) return AppTheme.alertAmber;
    return AppTheme.alertRed;
  }

  IconData _getTurnoIcon() {
    switch (widget.turno.toLowerCase()) {
      case 'mañana':
        return Icons.wb_sunny_rounded;
      case 'tarde':
        return Icons.wb_twilight_rounded;
      case 'noche':
        return Icons.nightlight_round;
      case 'madrugada':
        return Icons.dark_mode_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final currentScore = _scoreAnimation.value;
        final scoreColor = _getScoreColor(currentScore);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderTactical, width: 0.5),
            boxShadow: isDark
                ? [BoxShadow(color: scoreColor.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: -4)]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Encabezado ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_rounded, color: scoreColor, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SCORE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(_getTurnoIcon(), size: 14, color: isDark ? AppTheme.textMuted : Colors.grey[400]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: SizedBox(
                      width: 60, // Límite de ancho para que el texto haga scroll
                      child: _AutoScrollText(
                        text: widget.turno.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textMuted : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Arco Gauge ──
              SizedBox(
                width: widget.size,
                height: widget.size * 0.70, // Un poco más de altura para evitar overflow
                child: CustomPaint(
                  painter: _GaugePainter(
                    score: currentScore,
                    color: scoreColor,
                    isDark: isDark,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: widget.size * 0.35), // Lo bajamos aún más para que quede perfecto al centro
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            currentScore.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: widget.size * 0.22, // Escala dinámicamente según el tamaño (ej: ~21pt para size 95)
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: widget.size * 0.08, // Escala proporcionalmente
                              color: isDark ? AppTheme.textMuted : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Mensaje ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  // Forzamos remover el texto que manda el backend / padre
                  (widget.mensaje.isNotEmpty ? widget.mensaje : _defaultMessage(currentScore))
                      .replaceAll(' — mantente alerta', ''),
                  style: TextStyle(
                    fontSize: widget.size * 0.10, // Escala el texto inferior al tamaño del marco
                    fontWeight: FontWeight.w600,
                    color: scoreColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _defaultMessage(double score) {
    if (score >= 80) return 'Zona segura';
    if (score >= 50) return 'Precaución recomendada';
    return 'Alto riesgo';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Painter: Arco semicircular del gauge
// ═══════════════════════════════════════════════════════════════════════════

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final bool isDark;

  _GaugePainter({required this.score, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;
    const startAngle = math.pi * 0.85;
    const sweepTotal = math.pi * 1.3;
    final sweepAngle = sweepTotal * (score / 100).clamp(0.0, 1.0);

    // Fondo del arco
    final bgPaint = Paint()
      ..color = isDark ? AppTheme.bgDeep : Colors.grey.shade200
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Arco de progreso
    final progressPaint = Paint()
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [color.withValues(alpha: 0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Punto final del arco (indicador)
    final endAngle = startAngle + sweepAngle;
    final dotX = center.dx + radius * math.cos(endAngle);
    final dotY = center.dy + radius * math.sin(endAngle);

    // Glow del punto
    if (isDark) {
      canvas.drawCircle(
        Offset(dotX, dotY),
        8,
        Paint()..color = color.withValues(alpha: 0.3),
      );
    }

    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()..color = color,
    );

    canvas.drawCircle(
      Offset(dotX, dotY),
      2.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  AutoScrollText: Texto automático deslizante bidireccional
// ═══════════════════════════════════════════════════════════════════════════

class _AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _AutoScrollText({required this.text, required this.style});

  @override
  _AutoScrollTextState createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<_AutoScrollText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Rotación lenta, tipo panel publicitario
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500), // Mucho más calmado (antes 3000)
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      // Bucle infinito hacia la izquierda solamente
      _animationController.repeat(reverse: false);
      _animationController.addListener(() {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (maxScroll > 0) {
            _scrollController.jumpTo(maxScroll * _animationController.value);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), // Animación automática
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        // Repetimos el texto con espacio para crear la ilusión del bucle (efecto panel)
        child: Text("${widget.text}      ${widget.text}", style: widget.style),
      ),
    );
  }
}
