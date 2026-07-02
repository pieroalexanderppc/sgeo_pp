// Nueva pantalla: resumen operativo del dia para el rol policia (3 contadores).
// Rediseño visual v2: numeros de los contadores en Inter Bold 32px (antes 28px/w800).
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/map_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_card.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class PoliceInicioView extends StatefulWidget {
  const PoliceInicioView({super.key});

  @override
  State<PoliceInicioView> createState() => _PoliceInicioViewState();
}

class _PoliceInicioViewState extends State<PoliceInicioView> {
  bool _isLoading = true;
  int _pendientes = 0;
  int _confirmadosHoy = 0;
  int _rechazadosHoy = 0;

  @override
  void initState() {
    super.initState();
    _fetchCounters();
    ReportService.reportsUpdatedNotifier.addListener(_onReportsUpdated);
  }

  @override
  void dispose() {
    ReportService.reportsUpdatedNotifier.removeListener(_onReportsUpdated);
    super.dispose();
  }

  void _onReportsUpdated() {
    if (mounted) _fetchCounters();
  }

  bool _esHoy(dynamic rawFecha) {
    if (rawFecha == null) return false;
    try {
      final fecha = DateTime.parse(rawFecha.toString()).toLocal();
      final ahora = DateTime.now();
      return fecha.year == ahora.year &&
          fecha.month == ahora.month &&
          fecha.day == ahora.day;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchCounters() async {
    setState(() => _isLoading = true);
    try {
      final reportes = await MapService.fetchPuntosPolicia();
      int pendientes = 0;
      int confirmadosHoy = 0;
      int rechazadosHoy = 0;

      for (final r in reportes) {
        final estado = (r['estado'] ?? '').toString().toLowerCase();
        if (estado == 'pendiente') {
          pendientes++;
        } else if (estado == 'confirmado' && _esHoy(r['confirmado_en'])) {
          confirmadosHoy++;
        } else if (estado == 'rechazado' && _esHoy(r['rechazado_en'])) {
          rechazadosHoy++;
        }
      }

      if (mounted) {
        setState(() {
          _pendientes = pendientes;
          _confirmadosHoy = confirmadosHoy;
          _rechazadosHoy = rechazadosHoy;
        });
      }
    } catch (e) {
      debugPrint('Error cargando contadores de policia: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Resumen Operativo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _fetchCounters,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCounters,
        child: _isLoading
            ? const SkeletonLoader(count: 3, padding: EdgeInsets.all(20))
            : ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    'ACTIVIDAD DE HOY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark
                          ? AppTheme.accentBlueLight
                          : AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCounterCard(
                        'Pendientes',
                        _pendientes,
                        Icons.hourglass_empty_rounded,
                        AppTheme.alertAmber,
                        isDark,
                      )
                      .animate()
                      .fadeIn(delay: 50.ms, duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 14),
                  _buildCounterCard(
                        'Confirmados hoy',
                        _confirmadosHoy,
                        Icons.check_circle_rounded,
                        AppTheme.successGreen,
                        isDark,
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 14),
                  _buildCounterCard(
                        'Rechazados hoy',
                        _rechazadosHoy,
                        Icons.cancel_rounded,
                        AppTheme.alertRed,
                        isDark,
                      )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),
                ],
              ),
      ),
    );
  }

  Widget _buildCounterCard(
    String title,
    int value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return SafetyCard(
      accentColor: color,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textPrimary : Colors.black87,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
