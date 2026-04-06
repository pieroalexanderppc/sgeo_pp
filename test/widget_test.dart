// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sgeo_pp/main.dart';

void main() {
  testWidgets('Smoke test para LoginView', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(
      isLoggedIn: false,
      userId: '',
      userName: '',
      userRole: 'ciudadano',
    ));

    // Verifica que la vista de login se muestre.
    expect(find.text('Iniciar Sesión - SGEO'), findsOneWidget);
    expect(find.text('Ingresar al Sistema'), findsOneWidget);
  });
}
