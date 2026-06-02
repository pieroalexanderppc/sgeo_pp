import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class SplashView extends StatefulWidget {
  final Widget targetHome;

  const SplashView({super.key, required this.targetHome});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Simular tiempo de carga táctico
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.targetHome,
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep, // Fondo profundo táctico
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive logo size
          double responsiveLogoSize = constraints.maxWidth * 0.35;
          if (responsiveLogoSize > 180) responsiveLogoSize = 180;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo corporativo
                Container(
                      width: responsiveLogoSize,
                      height: responsiveLogoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.bgSurface,
                        border: Border.all(
                          color: AppTheme.borderTactical,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentBlue.withValues(
                              alpha: 0.2,
                            ), // Táctico glow
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.security, // Icono escudo táctico
                        size: responsiveLogoSize * 0.5,
                        color: AppTheme.accentBlue,
                      ),
                    )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.easeOutBack)
                    .shimmer(
                      delay: 900.ms,
                      duration: 1200.ms,
                      color: Colors.white24,
                    ),

                const SizedBox(height: 32),

                // 2. Nombre del Proyecto SGEO
                Text(
                      'SGEO',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8.0,
                            color: AppTheme.textPrimary,
                          ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 8),

                // 3. Subtítulo corporativo
                Text(
                  'SISTEMA DE SEGURIDAD',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.accentBlueLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.5,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                const SizedBox(height: 48),

                // 4. Indicador de carga
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentBlue,
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}
