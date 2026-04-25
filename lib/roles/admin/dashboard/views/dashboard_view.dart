import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab 1: Live Reports
  bool _isLoadingLive = true;
  String _selectedFiltroTiempo = 'Todos';
  Map<String, dynamic> _liveStats = {
    'total': 0,
    'por_tipo': {},
    'por_estado': {}
  };

  // Tab 2: Big Data SIDPOL
  bool _isLoadingBigData = true;
  Map<String, dynamic> _sidpolStats = {};
  Map<String, dynamic> _sidpolPred = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLiveStats();
    _fetchBigDataStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveStats() async {
    setState(() => _isLoadingLive = true);
    try {
      final res = await http.get(
        Uri.parse('https://sgeo-backend-production.up.railway.app/api/admin/dashboard_stats?filtro_tiempo=$_selectedFiltroTiempo'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _liveStats = data['stats'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error live stats: $e");
    } finally {
      if (mounted) setState(() => _isLoadingLive = false);
    }
  }

  Future<void> _fetchBigDataStats() async {
    setState(() => _isLoadingBigData = true);
    try {
      final resStats = await http.get(Uri.parse('https://sgeo-backend-production.up.railway.app/api/admin/sidpol_stats'));
      final resPred = await http.get(Uri.parse('https://sgeo-backend-production.up.railway.app/api/admin/sidpol_predict'));
      
      if (resStats.statusCode == 200 && resPred.statusCode == 200) {
        final dStats = json.decode(resStats.body);
        final dPred = json.decode(resPred.body);
        
        if (dStats['status'] == 'success' && dPred['status'] == 'success') {
          setState(() {
            _sidpolStats = dStats['stats'];
            _sidpolPred = dPred;
          });
        }
      }
    } catch (e) {
      debugPrint("Error big data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingBigData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Dashboard de Análisis'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentBlue,
          labelColor: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[700],
          tabs: const [
            Tab(icon: Icon(Icons.speed_rounded), text: 'App en Vivo'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Big Data (SIDPOL)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveTab(isDark),
          _buildBigDataTab(isDark),
        ],
      ),
    );
  }

  Widget _buildLiveTab(bool isDark) {
    if (_isLoadingLive) return const Center(child: CircularProgressIndicator());
    
    return RefreshIndicator(
      onRefresh: _fetchLiveStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Periodo de Análisis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textSecondary : Colors.grey[700],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgElevated : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppTheme.borderTactical : Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFiltroTiempo,
                      dropdownColor: isDark ? AppTheme.bgElevated : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'Todos', child: Text('Histórico Total')),
                        DropdownMenuItem(value: 'Mes Actual', child: Text('Mes Actual')),
                        DropdownMenuItem(value: 'Ultimos 3 Meses', child: Text('Últimos 3 Meses')),
                        DropdownMenuItem(value: 'Ultimos 6 Meses', child: Text('Últimos 6 Meses')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFiltroTiempo = val);
                          _fetchLiveStats();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildKPICard(title: 'Total Reportes', value: _liveStats['total'].toString(), icon: Icons.assignment_late_rounded, color: AppTheme.accentBlue, isDark: isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildKPICard(title: 'Pendientes', value: (_liveStats['por_estado']['pendiente'] ?? 0).toString(), icon: Icons.hourglass_empty_rounded, color: AppTheme.alertAmber, isDark: isDark)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildKPICard(title: 'Confirmados', value: (_liveStats['por_estado']['confirmado'] ?? 0).toString(), icon: Icons.check_circle_rounded, color: AppTheme.successGreen, isDark: isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildKPICard(title: 'Rechazados', value: (_liveStats['por_estado']['rechazado'] ?? 0).toString(), icon: Icons.cancel_rounded, color: AppTheme.alertRed, isDark: isDark)),
              ],
            ),
            const SizedBox(height: 32),
            SafetyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DISTRIBUCIÓN POR TIPO DE DELITO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: _liveStats['por_tipo'].isEmpty 
                        ? const Center(child: Text('No hay datos suficientes'))
                        : PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: _buildPieSections(isDark, _liveStats['por_tipo'], _liveStats['total']))),
                  ),
                  const SizedBox(height: 24),
                  ...(_liveStats['por_tipo'] as Map).entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: _getColorForType(e.key.toString()), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.key.toString(), style: const TextStyle(fontSize: 13))),
                          Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigDataTab(bool isDark) {
    if (_isLoadingBigData) return const Center(child: CircularProgressIndicator());
    if (_sidpolStats.isEmpty || _sidpolPred.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_rounded, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Sin datos históricos en SIDPOL'),
            TextButton(onPressed: _fetchBigDataStats, child: const Text('Actualizar'))
          ],
        )
      );
    }

    final distritoRiesgo = _sidpolPred['distrito_riesgo'];
    final valorRiesgo = _sidpolPred['valor_riesgo'];
    final List predsGlobales = _sidpolPred['predicciones_globales'] ?? [];
    
    return RefreshIndicator(
      onRefresh: _fetchBigDataStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI PREDICTION CARD
            SafetyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 24),
                      const SizedBox(width: 8),
                      Text('PREDICCIÓN IA (PRÓXIMOS MESES)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.purpleAccent)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Distrito con mayor riesgo proyectado:', style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.grey[700])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          distritoRiesgo.toString().toUpperCase(), 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.alertRed),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.alertRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text('+$valorRiesgo casos/mes', style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold, fontSize: 13)),
                      )
                    ],
                  ),
                  const Divider(height: 32),
                  if (predsGlobales.isNotEmpty) ...[
                    Text('Tendencia General Estimada:', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[700])),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: predsGlobales.map((p) => Column(
                        children: [
                          Text('${p["mes"]}/${p["anio"]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${p["prediccion"]} casos', style: TextStyle(color: isDark ? AppTheme.textMuted : Colors.grey, fontSize: 12)),
                        ],
                      )).toList(),
                    )
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // TOP DISTRICTS (BAR CHART MOCKUP OR LIST)
            SafetyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOP DISTRITOS CON MÁS INCIDENCIAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue)),
                  const SizedBox(height: 16),
                  ...(_sidpolStats['por_distrito'] as Map).entries.take(5).map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.location_city_rounded, size: 18, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.key.toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // TOP TIPOS DE DELITO SIDPOL
            SafetyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DISTRIBUCIÓN DE DELITOS HISTÓRICA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _sidpolStats['por_tipo'].isEmpty 
                        ? const Center(child: Text('Sin datos'))
                        : PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: _buildPieSectionsSidpol(isDark, _sidpolStats['por_tipo']))),
                  ),
                  const SizedBox(height: 24),
                  ...(_sidpolStats['por_tipo'] as Map).entries.take(5).map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: _getColorForType(e.key.toString()), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.key.toString(), style: const TextStyle(fontSize: 13))),
                          Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return SafetyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? AppTheme.textPrimary : Colors.black87)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textSecondary : Colors.grey[600])),
        ],
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'ROBO': return AppTheme.alertRed;
      case 'HURTO': return AppTheme.alertAmber;
      case 'EXTORSION': return Colors.purpleAccent;
      case 'HOMICIDIO': return Colors.red[900]!;
      case 'SECUESTRO': return Colors.deepOrange;
      default: return AppTheme.accentBlue;
    }
  }

  List<PieChartSectionData> _buildPieSections(bool isDark, Map tipos, dynamic total) {
    if (tipos.isEmpty || total == 0) return [];
    return tipos.entries.map((entry) {
      final value = (entry.value as num).toDouble();
      return PieChartSectionData(color: _getColorForType(entry.key), value: value, title: '${((value / total) * 100).toStringAsFixed(1)}%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white));
    }).toList();
  }

  List<PieChartSectionData> _buildPieSectionsSidpol(bool isDark, Map tipos) {
    if (tipos.isEmpty) return [];
    double total = 0;
    for (var v in tipos.values) { total += (v as num).toDouble(); }
    if (total == 0) return [];
    
    return tipos.entries.map((entry) {
      final value = (entry.value as num).toDouble();
      return PieChartSectionData(color: _getColorForType(entry.key), value: value, title: '${((value / total) * 100).toStringAsFixed(1)}%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white));
    }).toList();
  }
}
