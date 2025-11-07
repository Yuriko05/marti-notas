import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marti_notas/widgets/bulk_actions_bar.dart';

void main() {
  group('BulkActionsBar Widget Tests', () {
    testWidgets('Should display selected count', (WidgetTester tester) async {
      int clearCalled = 0;
      int reassignCalled = 0;
      int priorityCalled = 0;
      int deleteCalled = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 3,
              onClearSelection: () => clearCalled++,
              onReassign: () => reassignCalled++,
              onChangePriority: () => priorityCalled++,
              onDelete: () => deleteCalled++,
            ),
          ),
        ),
      );

      // Verificar que muestra el contador
      expect(find.text('3 seleccionadas'), findsOneWidget);

      // Verificar que existen los botones de acción
      expect(find.text('Reasignar'), findsOneWidget);
      expect(find.text('Prioridad'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('Should call clear selection callback', (WidgetTester tester) async {
      int clearCalled = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 2,
              onClearSelection: () => clearCalled++,
              onReassign: () {},
              onChangePriority: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Buscar y pulsar el botón de cerrar
      final clearButton = find.byIcon(Icons.close);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();

      expect(clearCalled, 1);
    });

    testWidgets('Should call reassign callback', (WidgetTester tester) async {
      int reassignCalled = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 5,
              onClearSelection: () {},
              onReassign: () => reassignCalled++,
              onChangePriority: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Buscar y pulsar el botón Reasignar
      final reassignButton = find.text('Reasignar');
      expect(reassignButton, findsOneWidget);
      await tester.tap(reassignButton);
      await tester.pump();

      expect(reassignCalled, 1);
    });

    testWidgets('Should call delete callback', (WidgetTester tester) async {
      // Configurar tamaño de pantalla más grande para evitar scroll
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      int deleteCalled = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 1,
              onClearSelection: () {},
              onReassign: () {},
              onChangePriority: () {},
              onDelete: () => deleteCalled++,
            ),
          ),
        ),
      );

      // Buscar y pulsar el botón Eliminar
      final deleteButton = find.text('Eliminar');
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pump();

      expect(deleteCalled, 1);
    });

    testWidgets('Should display singular form for one selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 1,
              onClearSelection: () {},
              onReassign: () {},
              onChangePriority: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verificar forma singular
      expect(find.text('1 seleccionada'), findsOneWidget);
    });

    testWidgets('Should show mark as read button when provided', (WidgetTester tester) async {
      int markReadCalled = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 2,
              onClearSelection: () {},
              onReassign: () {},
              onChangePriority: () {},
              onDelete: () {},
              onMarkAsRead: () => markReadCalled++,
            ),
          ),
        ),
      );

      // Verificar que existe el botón "Leído"
      expect(find.text('Leído'), findsOneWidget);

      // Pulsar el botón
      await tester.tap(find.text('Leído'));
      await tester.pump();

      expect(markReadCalled, 1);
    });

    testWidgets('Should not show mark as read button when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 2,
              onClearSelection: () {},
              onReassign: () {},
              onChangePriority: () {},
              onDelete: () {},
              // onMarkAsRead no proporcionado
            ),
          ),
        ),
      );

      // Verificar que NO existe el botón "Leído"
      expect(find.text('Leído'), findsNothing);
    });
  });
}
