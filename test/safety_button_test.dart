// Pruebas de widget del componente SafetyButton (core/widgets/safety_button.dart),
// el botón estándar del design system usado por los 3 roles.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sgeo_pp/core/widgets/safety_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  testWidgets('renderiza el label y el ícono', (tester) async {
    await tester.pumpWidget(_wrap(
      SafetyButton(
        label: 'GUARDAR',
        icon: Icons.save,
        onPressed: () {},
      ),
    ));

    expect(find.text('GUARDAR'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
  });

  testWidgets('ejecuta onPressed al tocar', (tester) async {
    var presionado = 0;
    await tester.pumpWidget(_wrap(
      SafetyButton(label: 'OK', onPressed: () => presionado++),
    ));

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(presionado, 1);
  });

  testWidgets('onPressed null deshabilita el botón sin lanzar errores', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(
      const SafetyButton(label: 'DESHABILITADO', onPressed: null),
    ));

    await tester.tap(find.text('DESHABILITADO'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('isLoading muestra spinner y oculta el label', (tester) async {
    await tester.pumpWidget(_wrap(
      SafetyButton(label: 'ENVIAR', isLoading: true, onPressed: () {}),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('ENVIAR'), findsNothing);
  });

  testWidgets('expand:false ajusta el ancho al contenido (con ícono)', (
    tester,
  ) async {
    // Con ícono el contenido es un Row: expandido ocupa todo el ancho,
    // compacto se ajusta al contenido (es el caso del botón REPORTAR del mapa).
    await tester.pumpWidget(_wrap(
      SafetyButton.danger(
        label: 'REPORTAR',
        icon: Icons.campaign_rounded,
        onPressed: () {},
      ),
    ));
    final anchoExpandido = tester.getSize(find.byType(SafetyButton)).width;

    await tester.pumpWidget(_wrap(
      SafetyButton.danger(
        label: 'REPORTAR',
        icon: Icons.campaign_rounded,
        expand: false,
        onPressed: () {},
      ),
    ));
    final anchoCompacto = tester.getSize(find.byType(SafetyButton)).width;

    expect(anchoCompacto, lessThan(anchoExpandido));
  });
}
