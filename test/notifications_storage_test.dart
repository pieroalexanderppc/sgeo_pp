// Pruebas unitarias del almacenamiento local de notificaciones
// (core/services/notifications_storage_service.dart) usando el mock de
// SharedPreferences — sin tocar Firebase real (RemoteMessage es una clase de datos).

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sgeo_pp/core/services/notifications_storage_service.dart';

RemoteMessage _push({String type = 'incident', String title = 'Alerta'}) {
  return RemoteMessage(
    notification: RemoteNotification(title: title, body: 'Cuerpo de prueba'),
    data: {'type': type},
  );
}

/// El id de cada notificación es millisecondsSinceEpoch: dos saves en el mismo
/// milisegundo colisionarían. Este helper separa los saves 2 ms para que los
/// tests sean deterministas (en producción dos push nunca llegan en el mismo ms).
Future<void> _guardar(RemoteMessage m) async {
  await NotificationsStorageService.saveFromRemoteMessage(m);
  await Future.delayed(const Duration(milliseconds: 2));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sin datos guardados devuelve lista vacía', () async {
    expect(await NotificationsStorageService.getNotifications(), isEmpty);
    expect(await NotificationsStorageService.getUnreadCount(), 0);
  });

  test('saveFromRemoteMessage guarda la notificación como no leída', () async {
    await NotificationsStorageService.saveFromRemoteMessage(_push());

    final notifs = await NotificationsStorageService.getNotifications();
    expect(notifs, hasLength(1));
    expect(notifs.first['title'], 'Alerta');
    expect(notifs.first['type'], 'incident');
    expect(notifs.first['isRead'], false);
    expect(await NotificationsStorageService.getUnreadCount(), 1);
  });

  test('la notificación más nueva queda primera en la lista', () async {
    await _guardar(_push(title: 'Primera'));
    await _guardar(_push(title: 'Segunda'));

    final notifs = await NotificationsStorageService.getNotifications();
    expect(notifs.first['title'], 'Segunda');
  });

  test('markAsRead marca solo la notificación indicada', () async {
    await _guardar(_push(title: 'A'));
    await _guardar(_push(title: 'B'));
    final notifs = await NotificationsStorageService.getNotifications();
    final idA = notifs.firstWhere((n) => n['title'] == 'A')['id'].toString();

    await NotificationsStorageService.markAsRead(idA);

    expect(await NotificationsStorageService.getUnreadCount(), 1);
  });

  test('markAllAsRead deja el contador de no leídas en cero', () async {
    await _guardar(_push());
    await _guardar(_push());

    await NotificationsStorageService.markAllAsRead();

    expect(await NotificationsStorageService.getUnreadCount(), 0);
  });

  test('deleteNotification elimina solo la indicada', () async {
    await _guardar(_push(title: 'A'));
    await _guardar(_push(title: 'B'));
    final notifs = await NotificationsStorageService.getNotifications();
    final idA = notifs.firstWhere((n) => n['title'] == 'A')['id'].toString();

    await NotificationsStorageService.deleteNotification(idA);

    final restantes = await NotificationsStorageService.getNotifications();
    expect(restantes, hasLength(1));
    expect(restantes.first['title'], 'B');
  });

  test('clearAll borra todo el historial', () async {
    await NotificationsStorageService.saveFromRemoteMessage(_push());

    await NotificationsStorageService.clearAll();

    expect(await NotificationsStorageService.getNotifications(), isEmpty);
  });

  test('un push sin bloque notification se ignora', () async {
    await NotificationsStorageService.saveFromRemoteMessage(
      const RemoteMessage(data: {'type': 'update'}),
    );
    expect(await NotificationsStorageService.getNotifications(), isEmpty);
  });
}
