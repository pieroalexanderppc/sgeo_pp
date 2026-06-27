// Rediseño visual v2: logo con fadeIn+scale, nombre en Rajdhani/accentCyan,
// subtitulo actualizado, indicador de carga ahora es una barra delgada al pie.
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
      body: Stack(
        children: [
          LayoutBuilder(
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
                                color: AppTheme.accentCyan.withValues(
                                  alpha: 0.25,
                                ), // Táctico glow
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.security, // Icono escudo táctico
                            size: responsiveLogoSize * 0.5,
                            color: AppTheme.accentCyan,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .shimmer(
                          delay: 900.ms,
                          duration: 1200.ms,
                          color: Colors.white24,
                        ),

                    const SizedBox(height: 32),

                    // 2. Nombre del Proyecto SGEO
                    Text(
                          'SGEO',
                          style: AppTheme.displayFont(
                            fontSize: 36,
                            weight: FontWeight.w800,
                            color: AppTheme.accentCyan,
                            letterSpacing: 6.0,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 8),

                    // 3. Subtítulo corporativo
                    Text(
                      'Sistema de Geolocalización de Inseguridad Ciudadana',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                  ],
                ),
              );
            },
          ),

          // 4. Indicador de carga: barra delgada al pie de la pantalla
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.bgSurface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.accentCyan,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 1000.ms),
        ],
      ),
    );
  }
}
