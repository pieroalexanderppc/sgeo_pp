// Rediseño visual v2: swipe-to-dismiss por notificacion (nuevo
// NotificationsStorageService.deleteNotification), leidas con opacidad 70%,
// "Marcar todas" ahora es un TextButton en accentCyan (antes IconButton).
// Rediseño visual v2 (BLOQUE 7): SkeletonLoader (shimmer) reemplaza el spinner de carga.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/notifications_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  // Lista donde guardaremos el historial desde SharedPreferences
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    NotificationsStorageService.updateNotifier.addListener(_onStorageUpdated);
  }

  void _onStorageUpdated() {
    if (mounted) _loadNotifications();
  }

  @override
  void dispose() {
    NotificationsStorageService.updateNotifier.removeListener(
      _onStorageUpdated,
    );
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final storedNotifs = await NotificationsStorageService.getNotifications();
    setState(() {
      _notifications = storedNotifs;
      _isLoading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    await NotificationsStorageService.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _markAsRead(int index) async {
    if (!_notifications[index]['isRead']) {
      await NotificationsStorageService.markAsRead(
        _notifications[index]['id'].toString(),
      );
      await _loadNotifications();
    }
  }

  // Método opcional para limpiar
  Future<void> _clearAll() async {
    await NotificationsStorageService.clearAll();
    await _loadNotifications();
  }

  // Swipe-to-dismiss: borra una sola notificación
  Future<void> _deleteOne(String id) async {
    await NotificationsStorageService.deleteNotification(id);
    await _loadNotifications();
  }

  // ── Ícono y color según tipo de notificación ──
  IconData _getIconForType(String type) {
    switch (type) {
      case 'risk_zone':
        return Icons.warning_rounded;
      case 'incident':
        return Icons.local_police_rounded;
      case 'update':
        return Icons.map_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type, BuildContext context) {
    final securityColors = Theme.of(context).extension<SecurityColors>();
    switch (type) {
      case 'risk_zone':
        return securityColors?.critical ?? AppTheme.alertRed;
      case 'incident':
        return securityColors?.warning ?? AppTheme.accentBlue;
      case 'update':
        return securityColors?.success ?? AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getIconBgColor(String type, bool isDark, BuildContext context) {
    final securityColors = Theme.of(context).extension<SecurityColors>();
    switch (type) {
      case 'risk_zone':
        return securityColors?.criticalBg ?? AppTheme.alertRedBg;
      case 'incident':
        return (securityColors?.warning ?? AppTheme.accentBlue).withValues(
          alpha: 0.15,
        );
      case 'update':
        return (securityColors?.success ?? AppTheme.successGreen).withValues(
          alpha: 0.15,
        );
      default:
        return isDark ? AppTheme.bgElevated : Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? AppTheme.textSecondary : null,
            ),
            onPressed: _clearAll,
            tooltip: "Borrar todas",
          ),
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Marcar todas',
              style: TextStyle(
                color: AppTheme.accentCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const SkeletonLoader(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            )
          : _notifications.isEmpty
          ? _buildEmptyView(isDark)
          : RefreshIndicator(
              color: AppTheme.accentCyan,
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  final bool isRead = notif['isRead'];
                  final String type = notif['type'] ?? '';
                  final iconColor = _getIconColor(type, context);
                  final iconBg = _getIconBgColor(type, isDark, context);

                  return Dismissible(
                        key: ValueKey(notif['id']),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteOne(notif['id'].toString()),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: AppTheme.alertRed,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isRead
                                ? (isDark
                                      ? AppTheme.bgSurface.withValues(
                                          alpha: 0.7,
                                        )
                                      : Theme.of(context).cardColor)
                                : (isDark
                                      ? AppTheme.bgElevated
                                      : Colors.blue.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? AppTheme.borderSubtle
                                  : iconColor.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _markAsRead(index),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ícono con fondo circular
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconForType(type),
                                      color: iconColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Textos
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif['title'],
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  color: isDark
                                                      ? AppTheme.textPrimary
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: iconColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif['message'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppTheme.textSecondary
                                                : Colors.grey[600],
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notif['time'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppTheme.accentBlueLight
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 50 * index),
                        duration: 300.ms,
                      )
                      .slideX(
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

  Widget _buildEmptyView(bool isDark) {
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppTheme.bgSurface : Colors.grey.shade100,
                    ),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      size: 56,
                      color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No tienes notificaciones",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textSecondary : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Las alertas de seguridad aparecerán aquí",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.textMuted : Colors.grey.shade500,
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
    );
  }
}
