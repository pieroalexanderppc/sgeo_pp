import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/models/report_model.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_card.dart';
import '../../../../core/widgets/safety_button.dart';

class MyReportsView extends StatefulWidget {
  final String userId;
  final Function(LatLng) onNavigateToMap; 
  
  const MyReportsView({super.key, required this.userId, required this.onNavigateToMap});

  @override
  State<MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<MyReportsView> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    setState(() => _isLoading = true);
    
    final reports = await ReportService.getMyReports(widget.userId);
    
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReport(ReportModel report) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppTheme.alertRed, size: 24),
            const SizedBox(width: 10),
            const Expanded(child: Text('Eliminar reporte')),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas eliminar permanentemente este reporte? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminando reporte...')));
    }

    final success = await ReportService.deleteReport(report.id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reporte eliminado con éxito.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _fetchMyReports(); // Reload list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hubo un error al eliminar el reporte.'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  void _showMapPreview(ReportModel report) {
    if (report.latitud == null || report.longitud == null) return;
    final latLng = LatLng(report.latitud!, report.longitud!);
    
    // Navegamos usando la función que viene desde HomeView hacia el mapa original
    widget.onNavigateToMap(latLng);
  }

  // ── Color del acento según estado del reporte ──
  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return AppTheme.alertAmber;
      case 'confirmado':
        return AppTheme.successGreen;
      case 'rechazado':
        return AppTheme.alertRed;
      case 'agrupado':
        return AppTheme.accentBlue;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.schedule;
      case 'confirmado':
        return Icons.check_circle;
      case 'rechazado':
        return Icons.cancel;
      case 'agrupado':
        return Icons.layers;
      default:
        return Icons.help_outline;
    }
  }

  void _showReportDetails(BuildContext context, ReportModel report, String formattedDate, String direccionStr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = report.estado.toLowerCase() == 'pendiente';
    final statusColor = _getStatusColor(report.estado);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppTheme.borderTactical, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle bar ──
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.textMuted : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Head
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        report.subTipo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.textPrimary : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Text(
                        report.estado.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Details
                _buildDetailRow(Icons.calendar_today, formattedDate, isDark),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on_outlined, direccionStr, isDark),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.comment_outlined,
                  report.descripcion != null && report.descripcion!.isNotEmpty 
                      ? report.descripcion! 
                      : "Sin descripción",
                  isDark,
                  isItalic: report.descripcion == null || report.descripcion!.isEmpty,
                ),
                const SizedBox(height: 24),

                // Buttons
                SafetyButton(
                  label: 'Ver zona en el Mapa',
                  icon: Icons.map_outlined,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showMapPreview(report);
                  },
                ),
                
                if (isPending) ...[
                  const SizedBox(height: 12),
                  SafetyButton.outline(
                    label: 'Eliminar Mi Reporte',
                    icon: Icons.delete_outline,
                    isDanger: true,
                    foregroundColor: AppTheme.alertRed,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteReport(report);
                    },
                  ),
                ],
                const SizedBox(height: 20), // Bottom safe space
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text, bool isDark, {bool isItalic = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? AppTheme.textMuted : Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? AppTheme.textSecondary : Colors.grey[700],
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafetyLayout(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMyReports,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyReports,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
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
                                  Icons.description_outlined,
                                  size: 48,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No has realizado ningún reporte',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.textSecondary : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tus reportes de seguridad aparecerán aquí',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 500.ms),
                        ),
                      )
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14.0),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    final statusColor = _getStatusColor(report.estado);
                    final statusIcon = _getStatusIcon(report.estado);
                    
                    DateTime? date;
                    if (report.creadoEn != null) {
                      try {
                        date = DateTime.parse(report.creadoEn!).toLocal();
                      } catch (e) {
                        debugPrint('Error parseando fecha: $e');
                      }
                    }
                    final formattedDate = date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : 'Fecha desconocida';

                    String direccionStr = report.direccion ?? '';
                    if (direccionStr.trim().isEmpty) {
                      if (report.latitud != null && report.longitud != null) {
                        final lat = report.latitud!.toStringAsFixed(5);
                        final lng = report.longitud!.toStringAsFixed(5);
                        direccionStr = 'GPS: Lat $lat, Lng $lng';
                      } else {
                        direccionStr = 'Ubicación por mapa';
                      }
                    }

                    return SafetyCard(
                      accentColor: statusColor,
                      margin: const EdgeInsets.only(bottom: 10),
                      onTap: () => _showReportDetails(context, report, formattedDate, direccionStr),
                      child: Row(
                        children: [
                          // ── Ícono de estado ──
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 22),
                          ),
                          const SizedBox(width: 14),

                          // ── Contenido ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.subTipo,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: isDark ? AppTheme.textPrimary : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  direccionStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppTheme.textMuted : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Estado badge + flecha ──
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  report.estado.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: isDark ? AppTheme.textMuted : Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 40 * index), duration: 300.ms)
                      .slideX(begin: 0.03, end: 0, duration: 300.ms, curve: Curves.easeOut);
                  },
                ),
      ),
    );
  }
}
