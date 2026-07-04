// Smoke test de arranque de la app (sin sesión → LoginView).
//
// Nota: los textos esperados corresponden al rediseño visual v2 de LoginView
// ('Bienvenido a SGEO' / botón 'Iniciar Sesión').

import 'package:flutter_test/flutter_test.dart';

import 'package:sgeo_pp/main.dart';

void main() {
  testWidgets('Sin sesión activa la app muestra el LoginView', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(isLoggedIn: false, userId: '', userName: '', userRole: 'ciudadano'),
    );

    // La app arranca en SplashView (3 s) y navega al Login con un fade de 800 ms.
    // Se usan pumps de duración fija: pumpAndSettle no termina si hay
    // animaciones en loop (flutter_animate).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bienvenido a SGEO'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Correo Electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
