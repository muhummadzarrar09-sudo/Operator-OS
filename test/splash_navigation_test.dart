import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/screens/sign_in_screen.dart';
import 'package:operator_os/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // Placeholder values, identical in spirit to the app's config. No network
    // call happens on initialize, so this just lets authProvider build.
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets(
      'Splash completes loading and advances to SignInScreen (no hang at 100%)',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SplashScreen())),
    );

    // While loading, the progress bar is on screen and we are NOT yet signed in.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);

    // Let the full intro animation play out (4800ms) plus the page transition
    // (520ms). We pump fixed durations rather than pumpAndSettle because the
    // SignInScreen runs an infinite ambient animation that never settles.
    //
    // If navigation were still blocked on restoreLocalMode (the reported bug),
    // the SignInScreen would never appear and these assertions would fail.
    await tester.pump(const Duration(milliseconds: 4800));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
