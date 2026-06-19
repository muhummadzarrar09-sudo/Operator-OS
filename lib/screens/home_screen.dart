import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/roadmap_provider.dart';
import 'package:operator_os/providers/user_initializer.dart';
import 'package:operator_os/screens/compound_screen.dart';
import 'package:operator_os/screens/journal_screen.dart';
import 'package:operator_os/screens/ai_hub_screen.dart';
import 'package:operator_os/screens/roadmap_screen.dart';
import 'package:operator_os/screens/sleep_log_screen.dart';
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

    final pages = [
      const TodayScreen(),
      const CompoundScreen(),
      const JournalScreen(),
      const SleepLogScreen(),
      const RoadmapScreen(),
      const AiHubScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Compound',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedtime),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Roadmap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}
