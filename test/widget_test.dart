import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/main.dart';

void main() {
  testWidgets('App builds and shows Splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OperatorOSApp()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Let the splash screen's delayed navigation complete.
    await tester.pump(const Duration(milliseconds: 700));
  });
}
