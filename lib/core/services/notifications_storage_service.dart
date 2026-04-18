import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

class NotificationsStorageService {
  static const String _key = 'user_notifications';
  
  // Notifier para avisar a la UI cuando cambian las notificaciones
  static ValueNotifier<int> updateNotifier = ValueNotifier(0);

  // Obtener todas las notificaciones
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Guardar una nueva notificación desde un Push
  static Future<void> saveFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final Map<String, dynamic> newNotif = {
      'id': id,
      // Usamos el campo 'type' en "data" si lo envías desde Python, 
      // si no, asigna 'incident' por defecto
      'type': message.data['type'] ?? 'incident',
      'title': notification.title ?? 'Aviso de Seguridad',
      'message': notification.body ?? '',
      'time': formattedDate,
      'isRead': false,
    };

    final List<Map<String, dynamic>> current = await getNotifications();
    current.insert(0, newNotif); // La más nueva va primero
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(current));
    
    // Avisamos a la UI que hay nueva info
    updateNotifier.value++;
  }

  // Marcar una como leída
  static Future<void> markAsRead(String id) async {
    final List<Map<String, dynamic>> current = await getNotifications();
    bool changed = false;
    for (var notif in current) {
      if (notif['id'] == id && notif['isRead'] == false) {
        notif['isRead'] = true;
        changed = true;
      }
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(current));
      updateNotifier.value++;
    }
  }

  // Marcar todas como leídas
  static Future<void> markAllAsRead() async {
    final List<Map<String, dynamic>> current = await getNotifications();
    for (var notif in current) {
      notif['isRead'] = true;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(current));
    updateNotifier.value++;
  }

  // Borrar todas (opcional por si lo piden después)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    updateNotifier.value++;
  }
}
