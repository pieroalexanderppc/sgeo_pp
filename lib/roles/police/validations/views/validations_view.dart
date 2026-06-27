// Reescrito: se agrega tab Historial, se usa PoliceService para confirmar/rechazar (compartido
// con el mapa), y se corrigen campos que no coincidian con el backend (sub_tipo/direccion/
// fecha_hecho -> subtipo_hecho/direccion_hecho/fecha_hora_hecho), que dejaban el subtipo y la
// direccion siempre en blanco.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/map_service.dart';
import '../../../../core/services/police_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_card.dart';

class ValidationsView extends StatefulWidget {
  final String userId;
  final Function(LatLng)? onNavigateToMap;

  const ValidationsView({super.key, required this.userId, this.onNavigateToMap});

  @override
  State<ValidationsView> createState() => _ValidationsViewState();
}

class _ValidationsViewState extends State<ValidationsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _pendingGrouped = [];
  List<dynamic> _historial = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchReportes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportes() async {
    setState(() => _isLoading = true);
    try {
      final reportes = await MapService.fetchPuntosPolicia();

      final pendientes = reportes.where((r) => (r['estado'] ?? '').toString().toLowerCase() == 'pendiente').toList();
      final historial = reportes
          .where((r) => ['confirmado', 'rechazado'].contains((r['estado'] ?? '').toString().toLowerCase()))
          .toList();

      // Agrupación visual de pendientes por proximidad (500 metros) y mismo subtipo
      final List<dynamic> grouped = [];
      for (var report in pendientes) {
        bool added = false;
        for (var group in grouped) {
          if (group['subtipo_hecho'] == report['subtipo_hecho']) {
            try {
              final c1 = report['ubicacion']['coordinates'];
              final c2 = group['ubicacion']['coordinates'];
              final distance = Geolocator.distanceBetween(
                c1[1] as double, c1[0] as double,
                c2[1] as double, c2[0] as double,
              );
              if (distance <= 500) {
                group['cantidad_agrupada'] = (group['cantidad_agrupada'] ?? 1) + 1;
                group['agrupados_list'] ??= [Map.from(group)];
                group['agrupados_list'].add(report);
                added = true;
                break;
              }
            } catch (_) {}
          }
        }
        if (!added) {
          report['cantidad_agrupada'] = 1;
          report['agrupados_list'] = [Map<String, dynamic>.from(report)];
          grouped.add(report);
        }
      }

      if (mounted) {
        setState(() {
          _pendingGrouped = grouped;
          _historial = historial;
        });
        PoliceService.pendingReportsNotifier.value = pendientes.length;
      }
    } catch (e) {
      debugPrint('Error listando reportes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String reportId, {required bool confirmar}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = confirmar ? AppTheme.successGreen : AppTheme.alertRed;
    final title = confirmar ? 'Validar Incidente' : 'Rechazar Incidente';
    final message = confirmar
        ? '¿Estás seguro de que deseas confirmar este reporte? Será visible para todos los ciudadanos.'
        : '¿Estás seguro de rechazar este reporte?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.borderTactical, width: 0.5)),
        title: Row(
          children: [
            Icon(confirmar ? Icons.check_circle_outline : Icons.cancel_outlined, color: accentColor, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(color: isDark ? AppTheme.textPrimary : Colors.black87, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message, style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.grey[800])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, elevation: 0),
            child: Text(confirmar ? 'Validar' : 'Rechazar', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando...')));
    }

    final resultado = confirmar
        ? await PoliceService.confirmarReporte(reportId)
        : await PoliceService.rechazarReporte(reportId);

    if (!mounted) return;

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message']), backgroundColor: accentColor),
      );
      _fetchReportes(); // Recalcula pendientes/historial y el badge
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message'] ?? 'No se pudo procesar el reporte.'), backgroundColor: AppTheme.alertRed),
      );
    }
  }

  void _showGroupDetails(BuildContext context, List<dynamic> group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppTheme.borderTactical, width: 0.5),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppTheme.textMuted : Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.alertAmber.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(Icons.list_alt, color: AppTheme.alertAmber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${group.length} Reportes Agrupados',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.textPrimary : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: group.length,
                itemBuilder: (context, index) {
                  final rep = group[index];
                  final desc = rep['descripcion'] ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgDeep : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: AppTheme.alertRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rep['direccion_hecho'] ?? 'GPS desconocido', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppTheme.textPrimary : Colors.black87)),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(desc, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[700])),
                              ],
                              const SizedBox(height: 4),
                              Text(_formatFecha(rep['fecha_hora_hecho']), style: TextStyle(fontSize: 12, color: AppTheme.accentBlueLight)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(dynamic raw) {
    if (raw == null) return 'Fecha desconocida';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(raw.toString()).toLocal());
    } catch (_) {
      return 'Fecha desconocida';
    }
  }

  Color _gravedadColor(dynamic gravedad) {
    switch ((gravedad ?? '').toString().toUpperCase()) {
      case 'ALTA':
        return AppTheme.alertRed;
      case 'BAJA':
        return AppTheme.successGreen;
      default:
        return AppTheme.alertAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Auditoría de Incidentes'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentBlue,
          labelColor: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[700],
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Historial'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.sync_rounded), onPressed: _fetchReportes),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendientesTab(isDark),
                _buildHistorialTab(isDark),
              ],
            ),
    );
  }

  Widget _buildPendientesTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _fetchReportes,
      child: _pendingGrouped.isEmpty
          ? _buildEmptyState(isDark, 'No hay reportes pendientes de validación')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              itemCount: _pendingGrouped.length,
              itemBuilder: (ctx, i) {
                final req = _pendingGrouped[i];
                final int count = req['cantidad_agrupada'] ?? 1;
                final String subTipo = req['subtipo_hecho'] ?? 'Incidente';
                final gravedadColor = _gravedadColor(req['gravedad']);

                return SafetyCard(
                  accentColor: AppTheme.alertAmber,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppTheme.alertAmber.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(Icons.warning_rounded, color: AppTheme.alertAmber, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  count > 1 ? '$subTipo ($count alertas)' : subTipo,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? AppTheme.textPrimary : Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  req['direccion_hecho'] ?? 'Ubicación GPS desconocida',
                                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[700]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFecha(req['fecha_hora_hecho']),
                                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted : Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          if (count > 1)
                            IconButton(
                              icon: Icon(Icons.list_alt, color: isDark ? AppTheme.textSecondary : Colors.grey, size: 24),
                              tooltip: "Ver detalles agrupados",
                              onPressed: () => _showGroupDetails(context, req['agrupados_list'] ?? []),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: gravedadColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'GRAVEDAD: ${(req['gravedad'] ?? 'MEDIA').toString().toUpperCase()}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: gravedadColor, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              final coords = req['ubicacion']['coordinates'];
                              final lng = coords[0] as double;
                              final lat = coords[1] as double;
                              widget.onNavigateToMap?.call(LatLng(lat, lng));
                            },
                            icon: Icon(Icons.map_outlined, color: AppTheme.accentBlueLight, size: 18),
                            label: Text("Ver", style: TextStyle(color: AppTheme.accentBlueLight)),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: Size.zero),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _updateStatus(req['_id'].toString(), confirmar: false),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppTheme.alertRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(Icons.close_rounded, color: AppTheme.alertRed, size: 22),
                            ),
                            tooltip: "Rechazar",
                          ),
                          IconButton(
                            onPressed: () => _updateStatus(req['_id'].toString(), confirmar: true),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppTheme.successGreen.withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: Icon(Icons.check_rounded, color: AppTheme.successGreen, size: 22),
                            ),
                            tooltip: "Validar",
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 50 * i), duration: 300.ms)
                    .slideY(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut);
              },
            ),
    );
  }

  Widget _buildHistorialTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _fetchReportes,
      child: _historial.isEmpty
          ? _buildEmptyState(isDark, 'Aún no hay reportes confirmados o rechazados')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              itemCount: _historial.length,
              itemBuilder: (ctx, i) {
                final rep = _historial[i];
                final estado = (rep['estado'] ?? '').toString().toLowerCase();
                final isConfirmado = estado == 'confirmado';
                final estadoColor = isConfirmado ? AppTheme.successGreen : AppTheme.alertRed;
                final fecha = isConfirmado ? rep['confirmado_en'] : rep['rechazado_en'];

                return SafetyCard(
                  accentColor: estadoColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(isConfirmado ? Icons.check_circle_rounded : Icons.cancel_rounded, color: estadoColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rep['subtipo_hecho'] ?? 'Incidente',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? AppTheme.textPrimary : Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rep['direccion_hecho'] ?? 'Ubicación GPS desconocida',
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondary : Colors.grey[700]),
                            ),
                            const SizedBox(height: 2),
                            Text(_formatFecha(fecha), style: TextStyle(fontSize: 11, color: isDark ? AppTheme.textMuted : Colors.grey[500])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          estado.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: estadoColor, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 30 * i), duration: 250.ms);
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? AppTheme.bgSurface : Colors.grey.shade100),
                  child: Icon(Icons.verified_user_outlined, size: 56, color: AppTheme.successGreen.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textSecondary : Colors.grey.shade600, height: 1.4),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 500.ms),
          ),
        ),
      ],
    );
  }
}
