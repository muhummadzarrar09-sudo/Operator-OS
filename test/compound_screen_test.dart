import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:operator_os/core/constants.dart';
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

  // Override SharedPreferences to avoid unconfigured platform errors.
  SharedPreferences.setMockInitialValues({
    'install_date_ms': DateTime(2024, 1, 1).millisecondsSinceEpoch,
  });

  group('CompoundScreen', () {
    testWidgets('renders 8 real + 8 ghost BuildingWidgets', (tester) async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());

      await StatsRepository(db).ensureStatsSeeded('test-user');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue('test-user'),
          ],
          child: const MaterialApp(home: CompoundScreen()),
        ),
      );

      // Wait for Drift streams + FutureProviders to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BuildingWidget), findsNWidgets(16));

      // Real buildings: not ghost.
      final realBuildings = find.byWidgetPredicate(
        (w) => w is BuildingWidget && !w.isGhost,
      );
      expect(realBuildings, findsNWidgets(8));

      // Ghost buildings: isGhost.
      final ghostBuildings = find.byWidgetPredicate(
        (w) => w is BuildingWidget && w.isGhost,
      );
      expect(ghostBuildings, findsNWidgets(8));

      // Flush disposal timers before teardown.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('tapping a real building navigates to StatDetailScreen', (tester) async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());

      await StatsRepository(db).ensureStatsSeeded('test-user');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue('test-user'),
          ],
          child: const MaterialApp(home: CompoundScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the first real BuildingWidget (finds tap target, not ghost overlay).
      await tester.tap(find.byWidgetPredicate((w) => w is BuildingWidget && !w.isGhost).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StatDetailScreen), findsOneWidget);
      expect(
        find.textContaining(StatKey.forge.label),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('FAB + debug dialog + +500 XP bumps craft tier 1→2', (tester) async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());

      await StatsRepository(db).ensureStatsSeeded('test-user');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue('test-user'),
          ],
          child: const MaterialApp(home: CompoundScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open FAB debug dialog.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find +500 button for Craft.
      final craftTile = find.widgetWithText(ListTile, 'Craft');
      expect(craftTile, findsOneWidget);

      final plus500 = find.descendant(
        of: craftTile,
        matching: find.text('+500'),
      );
      expect(plus500, findsOneWidget);
      await tester.tap(plus500);
      await tester.pump();

      // Rebuild CompoundScreen after XP update.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue('test-user'),
          ],
          child: const MaterialApp(home: CompoundScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the Craft building (real, not ghost) and verify tier changed to 2.
      final craftBuildings = find.byWidgetPredicate(
        (w) =>
            w is BuildingWidget &&
            !w.isGhost &&
            w.statKey == 'craft',
      );
      expect(craftBuildings, findsOneWidget);
      final craftWidget = tester.widget<BuildingWidget>(craftBuildings);
      expect(craftWidget.tier, 2); // 500 XP → level 3 → tier 2
      expect(craftWidget.level >= 3, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
