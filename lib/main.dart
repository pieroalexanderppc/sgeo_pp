import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/login_view.dart';
import 'roles/user/home/views/home_view.dart';
import 'roles/police/home/views/home_view.dart';
import 'roles/user/notifications/views/notifications_view.dart';
import 'core/services/notifications_storage_service.dart';
import 'core/services/map_service.dart';

// Función global encargada de manejar notificaciones entrantes cuando 
// la aplicación se encuentra en segundo plano (Background) o terminada.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Notificación en segundo plano recibida: ${message.messageId}');

  // Se almacena la alerta de manera persistente utilizando SharedPreferences
  if (message.notification != null) {
    await NotificationsStorageService.saveFromRemoteMessage(message);
  }
}

// Instancia requerida para ejecutar y manejar notificaciones locales (Foreground).
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Llave global del navegador. Se utiliza para redireccionar la vista sin contexto activo.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _handleNotificationTap(RemoteMessage message) async {
  if (navigatorKey.currentState == null) return;

  final Map<String, dynamic> data = message.data;
  final String type = data['type'] ?? '';

  if (type == 'update') {
    // Limpia la caché local y redirige al panel de notificaciones
    MapService.clearCache();
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (context) => const NotificationsView()),
    );
  } else if (type == 'incident' && data.containsKey('lat') && data.containsKey('lng')) {
    // Almacena las coordenadas y muestra la ubicación en el mapa
    final double? lat = double.tryParse(data['lat'].toString());
    final double? lng = double.tryParse(data['lng'].toString());

    if (lat != null && lng != null) {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role') ?? 'ciudadano';
      navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            if (userRole == 'policia') {
              return PoliceHomeView(
                userId: prefs.getString('user_id') ?? '',
                userName: prefs.getString('user_name') ?? '',
                userRole: userRole,
                // Si la vista de policía no acepta initialLocation, tal vez requiera ajustes,
                // Pero por ahora, se enviará a PoliceHomeView sin ello asumiendo que el policía
                // manejará la posición mediante su propio visor.
              );
            } else {
              return HomeView(
                userId: prefs.getString('user_id') ?? '',
                userName: prefs.getString('user_name') ?? '',
                userRole: userRole,
                initialLocation: LatLng(lat, lng),
              );
            }
          }
        ),
      );
    } else {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const NotificationsView()),
      );
    }
  } else {
    // Redirección por defecto si el tipo de alerta no está definido o es general
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (context) => const NotificationsView()),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicialización de los servicios en la nube (Firebase Core)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Registro del controlador para notificaciones en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Configuración y parámetros para Notificaciones Locales (Iconos y apariencia nativa)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // 4. Creación del Canal de Notificaciones para dispositivos con Android 8.0 o superior
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'sgeo_alertas_urgentes',
    'Alertas de Seguridad',
    description: 'Notificaciones críticas sobre incidentes y zonas de riesgo detectadas.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 5. Verificación y/o solicitud explícita de permisos de notificación.
  await FirebaseMessaging.instance.requestPermission();

  // 6. Obtención del token FCM único de registro del dispositivo
  String? token = await FirebaseMessaging.instance.getToken();
  debugPrint("\n==================================================");
  debugPrint("Token FCM Activo: $token");
  debugPrint("==================================================\n");

  // 7. Evento de escucha para notificaciones entrantes cuando la app se encuentra en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    final Map<String, dynamic> data = message.data;

    // Acción automática: Si es requerida una actualización de mapa, se limpia la caché del dispositivo
    if (data['type'] == 'update') {
      MapService.clearCache();
    }

    if (notification != null) {
      // Registrar la notificación en el historial local persistente
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

  // 8. Interacción de la notificación desde la barra de estado (Estado de Suspensión).
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    await _handleNotificationTap(message);
  });

  // 9. Interacción de la notificación cuando el servicio se encuentra totalmente terminado.
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // Retrasar invocación para asegurar la preconstrucción del Material App de Flutter
    Future.delayed(const Duration(milliseconds: 500), () async {
      await _handleNotificationTap(initialMessage);
    });
  }

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
          navigatorKey: navigatorKey,
          title: 'SGEO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: isLoggedIn 
                ? (userRole == 'policia' 
                    ? PoliceHomeView(userId: userId, userName: userName, userRole: userRole) 
                    : HomeView(userId: userId, userName: userName, userRole: userRole))
                : const LoginView(),
        );
      },
    );
  }
}
