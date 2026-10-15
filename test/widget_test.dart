import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f1_manager/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('F1 Manager App launches HomeScreen seamlessly on Mobile viewport', (WidgetTester tester) async {
    // Set standard mobile phone viewport (390x844)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const F1ManagerApp());
    await tester.pumpAndSettle();

    // Verify HomeScreen elements
    expect(find.text('MANAGER 2026'), findsOneWidget);
    expect(find.text('START NEW CAREER 🏎️'), findsOneWidget);
    expect(find.text('QUICK GRAND PRIX (STANDALONE WEEKEND)'), findsOneWidget);

    // Tap Start New Career to navigate to Team Selection
    await tester.tap(find.text('START NEW CAREER 🏎️'));
    await tester.pumpAndSettle();

    expect(find.text('SELECT CONSTRUCTOR'), findsOneWidget);
    expect(find.text('RED BULL'), findsOneWidget);
    expect(find.text('FERRARI'), findsOneWidget);
  });

  testWidgets('F1 Manager App launches seamlessly on Desktop/Tablet viewport', (WidgetTester tester) async {
    // Set desktop screen viewport (1280x800)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const F1ManagerApp());
    await tester.pumpAndSettle();

    expect(find.text('MANAGER 2026'), findsOneWidget);
    expect(find.text('START NEW CAREER 🏎️'), findsOneWidget);

    // Tap Start New Career
    await tester.tap(find.text('START NEW CAREER 🏎️'));
    await tester.pumpAndSettle();

    expect(find.text('SELECT YOUR CONSTRUCTOR'), findsOneWidget);
    expect(find.text('RED BULL'), findsOneWidget);
    expect(find.text('FERRARI'), findsOneWidget);
  });
}
