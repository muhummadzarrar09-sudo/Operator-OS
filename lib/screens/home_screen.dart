import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/roadmap_provider.dart';
import 'package:operator_os/providers/user_initializer.dart';
import 'package:operator_os/screens/ai_hub_screen.dart';
import 'package:operator_os/screens/compound_screen.dart';
import 'package:operator_os/screens/sign_in_screen.dart';
import 'package:operator_os/screens/today_screen.dart';
import 'package:operator_os/services/notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _notificationsScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleNotifications());
  }

  Future<void> _scheduleNotifications() async {
    if (_notificationsScheduled) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      final notif = NotificationService();
      await notif.requestPermissions();
      await notif.scheduleAll(
        fajrTime: const Time(5, 0),
        bedtimeTime: const Time(22, 30),
        scheduleSlots: true,
      );
      if (mounted) setState(() => _notificationsScheduled = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userInitializerProvider);
    ref.watch(roadmapInitializerProvider);

    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != null && next == null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
          (_) => false,
        );
      }
    });

    final pages = const [
      TodayScreen(),
      CompoundScreen(),
      AiHubScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: OperatorPalette.voidBlack.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: OperatorPalette.borderDim)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          indicatorColor: OperatorPalette.parchmentGold.withValues(alpha: 0.16),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Command',
            ),
            NavigationDestination(
              icon: Icon(Icons.castle_outlined),
              selectedIcon: Icon(Icons.castle),
              label: 'Compound',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology_alt_outlined),
              selectedIcon: Icon(Icons.psychology_alt),
              label: 'AI',
            ),
          ],
        ),
      ),
    );
  }
}
