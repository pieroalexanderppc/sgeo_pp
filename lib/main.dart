import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/login_view.dart';
import 'roles/user/home/views/home_view.dart';
import 'core/services/notifications_storage_service.dart';

// Función para manejar notificaciones cuando la app está en SEGUNDO PLANO (Cerrada)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Notificación en segundo plano recibida: ${message.messageId}');
  
  // Guardamos la notificación en Shared Preferences
  if (message.notification != null) {
    await NotificationsStorageService.saveFromRemoteMessage(message);
  }
}

// Instancia global para las notificaciones locales (las que hacen vibrar el cel)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar el núcleo mágico de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Escuchar la antena de Firebase cuando la app está CERRADA
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Configurar Notificaciones Locales (El icono de notificación en Android)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // 4. Crear el Canal de Notificaciones para Android (Obligatorio en Android 8+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'sgeo_alertas_urgentes', // Id interno
    'Alertas de Seguridad', // Nombre visual para el usuario
    description: 'Notificaciones sobre incidentes policiales y zonas de riesgo.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 5. Pedir permiso al usuario para mandarle alertas (pantallazo "SGEO te quiere mandar alertas")
  await FirebaseMessaging.instance.requestPermission();

  // 6. Suscribir a todos los celulares al canal global "actualizaciones"
  await FirebaseMessaging.instance.subscribeToTopic('actualizaciones');

  // Mostrar el Token en consola
  String? token = await FirebaseMessaging.instance.getToken();
  debugPrint("\n==================================================");
  debugPrint("🚀 Firebase Token de este celular: $token");
  debugPrint("==================================================\n");

  // 7. Escuchar notificaciones cuando la app ESTÁ ABIERTA en pantalla
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // Guardar también si estamos viendo la app
      await NotificationsStorageService.saveFromRemoteMessage(message);
    }

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  
  String? userId;
  String? userName;
  String? userRole;

  if (isLoggedIn) {
    userId = prefs.getString('user_id');
    userName = prefs.getString('user_name');
    userRole = prefs.getString('user_role');
  }

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    userId: userId ?? '',
    userName: userName ?? '',
    userRole: userRole ?? 'ciudadano',
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userId;
  final String userName;
  final String userRole;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'SGEO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: isLoggedIn 
                ? HomeView(userId: userId, userName: userName, userRole: userRole) 
                : const LoginView(),
        );
      },
    );
  }
}
