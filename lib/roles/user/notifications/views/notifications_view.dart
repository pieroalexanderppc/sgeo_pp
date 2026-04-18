import 'package:flutter/material.dart';
import '../../../../core/services/notifications_storage_service.dart';

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
    NotificationsStorageService.updateNotifier.removeListener(_onStorageUpdated);
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
      await NotificationsStorageService.markAsRead(_notifications[index]['id'].toString());
      await _loadNotifications();
    }
  }

  // Método opcional para limpiar
  Future<void> _clearAll() async {
    await NotificationsStorageService.clearAll();
    await _loadNotifications();
  }

  Icon _getIconForType(String type) {
    switch (type) {
      case 'risk_zone':
        return const Icon(Icons.warning_rounded, color: Colors.deepOrange, size: 28);
      case 'incident':
        return const Icon(Icons.local_police_rounded, color: Colors.blue, size: 28);
      case 'update':
        return const Icon(Icons.map_rounded, color: Colors.green, size: 28);
      default:
        return const Icon(Icons.notifications_rounded, color: Colors.grey, size: 28);
    }
  }

  Color _getBackgroundColor(String type, bool isRead, BuildContext context) {
    if (isRead) return Theme.of(context).cardColor;
    
    // Si no está leída, le damos un tono muy suave dependiendo del tipo
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case 'risk_zone':
        return isDark ? Colors.deepOrange.withAlpha(30) : Colors.deepOrange.withAlpha(15);
      case 'incident':
        return isDark ? Colors.blue.withAlpha(30) : Colors.blue.withAlpha(15);
      default:
        return isDark ? Colors.white10 : Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
             icon: const Icon(Icons.delete_outline),
             onPressed: _clearAll,
             tooltip: "Borrar todas",
          ),
          IconButton(
             icon: const Icon(Icons.done_all_rounded),
             onPressed: _markAllAsRead,
             tooltip: "Marcar todas como leídas",
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
            ? _buildEmptyView()
            : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 1, 
                thickness: 1, 
                color: Theme.of(context).dividerColor.withAlpha(50)
              ),
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final bool isRead = notif['isRead'];

                return InkWell(
                  onTap: () => _markAsRead(index),
                  child: Container(
                    color: _getBackgroundColor(notif['type'], isRead, context),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icono
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(isDark(context) ? 50 : 10), blurRadius: 5)
                            ]
                          ),
                          child: _getIconForType(notif['type']),
                        ),
                        const SizedBox(width: 16),
                        
                        // Textos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif['message'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notif['time'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.notifications_off_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100)),
           const SizedBox(height: 16),
           Text(
             "No tienes notificaciones nuevas", 
             style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
           ),
         ],
       )
    );
  }
}
