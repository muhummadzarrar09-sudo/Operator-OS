import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/screens/compound_screen.dart';
import 'package:operator_os/screens/stat_detail_screen.dart';
import 'package:operator_os/widgets/building_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'install_date_ms': DateTime(2024, 1, 1).millisecondsSinceEpoch,
  });

  Future<void> pumpForStreams(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> disposeAndFlush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 12; i++) {
      await tester.pump();
    }
  }

  Widget buildApp(AppDatabase db) => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          currentUserIdProvider.overrideWithValue('test-user'),
        ],
        child: const MaterialApp(home: CompoundScreen()),
      );

  testWidgets('CompoundScreen renders 8 real + 8 ghost BuildingWidgets',
      (tester) async {
    await tester.runAsync(() async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(db.close);
      await StatsRepository(db).ensureStatsSeeded('test-user');
      await tester.pumpWidget(buildApp(db));
      await pumpForStreams(tester);
      expect(find.byType(BuildingWidget), findsNWidgets(16));
      expect(find.byWidgetPredicate((w) => w is BuildingWidget && !w.isGhost), findsNWidgets(8));
      expect(find.byWidgetPredicate((w) => w is BuildingWidget && w.isGhost), findsNWidgets(8));
      await disposeAndFlush(tester);
    });
  });

  testWidgets('CompoundScreen tapping a real building navigates to StatDetailScreen',
      (tester) async {
    await tester.runAsync(() async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(db.close);
      await StatsRepository(db).ensureStatsSeeded('test-user');
      await tester.pumpWidget(buildApp(db));
      await pumpForStreams(tester);
      await tester.tap(find.byWidgetPredicate((w) => w is BuildingWidget && !w.isGhost).first);
      await pumpForStreams(tester);
      expect(find.byType(StatDetailScreen), findsOneWidget);
      expect(find.text('FORGE'), findsWidgets);
      await disposeAndFlush(tester);
    });
  });

  testWidgets('CompoundScreen FAB +500 XP on CRAFT bumps tier 1→2',
      (tester) async {
    await tester.runAsync(() async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(db.close);
      await StatsRepository(db).ensureStatsSeeded('test-user');
      await tester.pumpWidget(buildApp(db));
      await pumpForStreams(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await pumpForStreams(tester);
      final plus500 = find.descendant(of: find.widgetWithText(ListTile, 'Craft'), matching: find.text('+500'));
      await tester.tap(plus500);
      await pumpForStreams(tester);
      await tester.tap(find.text('Close'));
      await pumpForStreams(tester);
      final craftWidget = tester.widget<BuildingWidget>(
        find.byWidgetPredicate((w) => w is BuildingWidget && !w.isGhost && w.statKey == 'craft'),
      );
      expect(craftWidget.tier, 2);
      expect(craftWidget.level, greaterThanOrEqualTo(3));
      expect(craftWidget.currentXp, 500);
      await disposeAndFlush(tester);
    });
  });
}
