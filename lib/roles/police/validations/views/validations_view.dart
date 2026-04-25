import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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

class _ValidationsViewState extends State<ValidationsView> {
  bool _isLoading = true;
  List<dynamic> _pendingReports = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingReports();
  }

  Future<void> _fetchPendingReports() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'https://sgeo-backend-production.up.railway.app/api/reportes/policia',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          final allPending = (data['reportes'] as List)
              .where((r) => r['estado'].toString().toLowerCase() == 'pendiente')
              .toList();

          // Agrupación visual en la UI (500 metros)
          List<dynamic> grouped = [];
          for (var report in allPending) {
            bool added = false;
            for (var group in grouped) {
              if (group['sub_tipo'] == report['sub_tipo']) {
                try {
                  final c1 = report['ubicacion']['coordinates'];
                  final c2 = group['ubicacion']['coordinates'];
                  final distance = Geolocator.distanceBetween(
                    c1[1] as double, c1[0] as double,
                    c2[1] as double, c2[0] as double,
                  );
                  if (distance <= 500) {
                    group['cantidad_agrupada'] = (group['cantidad_agrupada'] ?? 1) + 1;
                    if (group['agrupados_list'] == null) {
                      group['agrupados_list'] = [Map.from(group)]; // Add self to list if first time
                    }
                    group['agrupados_list'].add(report);
                    added = true;
                    break;
                  }
                } catch (_) {}
              }
            }
            if (!added) {
              report['cantidad_agrupada'] = 1;
              
              // Evitar referencia circular copiando el mapa limpiamente
              final cleanReport = Map<String, dynamic>.from(report);
              report['agrupados_list'] = [cleanReport]; 
              
              grouped.add(report);
            }
          }

          setState(() {
            _pendingReports = grouped;
          });
        }
      }
    } catch (e) {
      debugPrint('Error listando reportes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String reportId, String newStatus) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mostramos un dialog de confirmación antes de validar o rechazar
    final isValidation = newStatus == 'VALIDADO';
    final accentColor = isValidation ? AppTheme.successGreen : AppTheme.alertRed;
    final iconData = isValidation ? Icons.check_circle_outline : Icons.cancel_outlined;
    final title = isValidation ? 'Validar Incidente' : 'Rechazar Incidente';
    final message = isValidation 
      ? '¿Estás seguro de que deseas confirmar este reporte? Será visible para todos los ciudadanos.' 
      : '¿Estás seguro de rechazar este reporte?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.borderTactical, width: 0.5)),
        title: Row(
          children: [
            Icon(iconData, color: accentColor, size: 28),
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
            child: Text(isValidation ? 'Validar' : 'Rechazar', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando...')));
    }

    try {
      final endpoint = newStatus == 'VALIDADO' 
        ? '/api/reportes/confirmar/$reportId' 
        : '/api/reportes/rechazar/$reportId';
        
      final res = await http.post(
        Uri.parse('https://sgeo-backend-production.up.railway.app$endpoint'),
      );
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte $newStatus exitosamente'),
            backgroundColor: isValidation ? AppTheme.successGreen : AppTheme.alertRed,
          ),
        );
        _fetchPendingReports();
      }
    } catch (_) {}
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
                              Text(rep['direccion'] ?? 'GPS desconocido', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppTheme.textPrimary : Colors.black87)),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(desc, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[700])),
                              ],
                              const SizedBox(height: 4),
                              Text('Fecha: ${rep['fecha_hecho']?.toString().split("T").first ?? "Desconocida"}', style: TextStyle(fontSize: 12, color: AppTheme.accentBlueLight)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Auditoría de Incidentes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _fetchPendingReports,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPendingReports,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingReports.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? AppTheme.bgSurface : Colors.grey.shade100,
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              size: 56,
                              color: AppTheme.successGreen.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Todo en orden",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.textPrimary : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No hay incidentes pendientes por validar.\n¡Buen trabajo!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.textSecondary : Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 500.ms),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                itemCount: _pendingReports.length,
                itemBuilder: (ctx, i) {
                  final req = _pendingReports[i];
                  final int count = req['cantidad_agrupada'] ?? 1;
                  final String subTipo = req['sub_tipo'] ?? 'Incidente';

                  return SafetyCard(
                    accentColor: AppTheme.alertAmber,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header de la tarjeta
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.alertAmber.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.warning_rounded, color: AppTheme.alertAmber, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    count > 1 ? '$subTipo ($count alertas)' : subTipo,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark ? AppTheme.textPrimary : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    req['direccion'] ?? 'Ubicación GPS desconocida',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppTheme.textSecondary : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (count > 1)
                              IconButton(
                                icon: Icon(Icons.list_alt, color: isDark ? AppTheme.textSecondary : Colors.grey, size: 24),
                                tooltip: "Ver detalles agrupados",
                                onPressed: () {
                                  _showGroupDetails(context, req['agrupados_list'] ?? []);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Acciones de validación
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                final coords = req['ubicacion']['coordinates'];
                                final lng = coords[0] as double;
                                final lat = coords[1] as double;
                                if (widget.onNavigateToMap != null) {
                                  widget.onNavigateToMap!(LatLng(lat, lng));
                                }
                              },
                              icon: Icon(Icons.map_outlined, color: AppTheme.accentBlueLight, size: 18),
                              label: Text("Ver", style: TextStyle(color: AppTheme.accentBlueLight)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: Size.zero,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _updateStatus(req['_id'].toString(), 'RECHAZADO'),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.alertRed.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close_rounded, color: AppTheme.alertRed, size: 22),
                              ),
                              tooltip: "Rechazar",
                            ),
                            IconButton(
                              onPressed: () => _updateStatus(req['_id'].toString(), 'VALIDADO'),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
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
      ),
    );
  }
}
