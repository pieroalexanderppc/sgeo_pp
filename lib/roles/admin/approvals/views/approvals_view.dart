// Nueva pantalla: panel de aprobacion/rechazo de policias pendientes (rol admin).
// Rediseño visual v2: StatusBadge reemplaza el chip "PENDIENTE DE VERIFICACIÓN" armado a mano.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_card.dart';
import '../../../../core/widgets/safety_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class ApprovalsView extends StatefulWidget {
  const ApprovalsView({super.key});

  @override
  State<ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<ApprovalsView> {
  bool _isLoading = true;
  List<dynamic> _pendingUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoading = true);
    final resultado = await AdminService.getUsuarios(pendiente: true);
    if (mounted) {
      if (resultado['success'] == true) {
        setState(() {
          _pendingUsers = resultado['usuarios'] as List;
          _isLoading = false;
        });
        AdminService.pendingCountNotifier.value = _pendingUsers.length;
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ?? 'No se pudo cargar la lista.',
            ),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  void _removeFromList(Map<String, dynamic> user) {
    setState(() => _pendingUsers.removeWhere((u) => u['_id'] == user['_id']));
    AdminService.pendingCountNotifier.value = _pendingUsers.length;
  }

  Future<void> _aprobar(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprobar solicitud'),
        content: Text('¿Aprobar la cuenta de ${user['nombre']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final resultado = await AdminService.aprobarUsuario(user['_id']);
    if (!mounted) return;

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cuenta aprobada. Se envió notificación a ${user['email']}',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      _removeFromList(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['message'] ?? 'No se pudo aprobar la cuenta.',
          ),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  Future<void> _rechazar(Map<String, dynamic> user) async {
    final motivoController = TextEditingController();
    bool motivoValido = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rechazar solicitud'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Escribe el motivo del rechazo para ${user['nombre']}:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: motivoController,
                    autofocus: true,
                    maxLines: 3,
                    onChanged: (val) => setDialogState(
                      () => motivoValido = val.trim().isNotEmpty,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Ej: Los datos enviados no coinciden con su DNI',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: motivoValido
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.alertRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Rechazar'),
                ),
              ],
            );
          },
        );
      },
    );

    final motivo = motivoController.text.trim();
    motivoController.dispose();
    if (confirm != true || motivo.isEmpty) return;

    final resultado = await AdminService.rechazarUsuario(user['_id'], motivo);
    if (!mounted) return;

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud rechazada. Se notificó a ${user['email']}'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      _removeFromList(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['message'] ?? 'No se pudo rechazar la cuenta.',
          ),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  String _formatFecha(dynamic raw) {
    if (raw == null) return 'Fecha desconocida';
    try {
      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.parse(raw.toString()).toLocal());
    } catch (_) {
      return 'Fecha desconocida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Solicitudes Policiales'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _fetchPending,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPending,
        child: _isLoading
            ? const SkeletonLoader()
            : _pendingUsers.isEmpty
            ? _buildEmptyState(isDark)
            : ListView.builder(
                padding: const EdgeInsets.all(14.0),
                itemCount: _pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = _pendingUsers[index] as Map<String, dynamic>;
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
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_police_rounded,
                                    color: AppTheme.accentBlue,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['nombre'] ?? 'Sin nombre',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: isDark
                                              ? AppTheme.textPrimary
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user['email'] ?? 'Sin correo',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppTheme.textSecondary
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Registrado: ${_formatFecha(user['creado_en'])}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppTheme.textMuted
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const StatusBadge(
                              status: 'pendiente',
                              label: 'PENDIENTE DE VERIFICACIÓN',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SafetyButton.outline(
                                    label: 'Rechazar',
                                    icon: Icons.close_rounded,
                                    foregroundColor: AppTheme.alertRed,
                                    isDanger: true,
                                    onPressed: () => _rechazar(user),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SafetyButton(
                                    label: 'Aprobar',
                                    icon: Icons.check_rounded,
                                    onPressed: () => _aprobar(user),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 50 * index),
                        duration: 300.ms,
                      )
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child:
                Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppTheme.bgSurface
                                : Colors.grey.shade100,
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 56,
                            color: AppTheme.successGreen.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No hay solicitudes policiales pendientes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textSecondary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                    ),
          ),
        ),
      ],
    );
  }
}
