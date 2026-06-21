import 'package:flutter/material.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String operatorOnboardingCompletePrefsKey = 'operator_os_onboarding_complete_v1';

Future<bool> hasCompletedOperatorOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(operatorOnboardingCompletePrefsKey) ?? false;
}

Future<void> setOperatorOnboardingComplete(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(operatorOnboardingCompletePrefsKey, value);
}

class OnboardingScreen extends StatefulWidget {
  final Widget? destination;

  const OnboardingScreen({this.destination, super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_WalkthroughPage> _pages = [
    _WalkthroughPage(
      icon: Icons.dashboard_customize_outlined,
      label: 'COMMAND CENTER',
      title: 'Start each day from Command.',
      body:
          'Command is your simple home base: today\'s missions, your XP, active missions, and quick jumps to Journal, Sleep, Roadmap, Campaigns, and the Compound.',
      bullets: [
        'Check missions due today.',
        'Complete missions to earn XP.',
        'Use quick actions when you need deeper tools.',
      ],
      color: OperatorPalette.parchmentGold,
    ),
    _WalkthroughPage(
      icon: Icons.castle_outlined,
      label: 'THE COMPOUND',
      title: 'Your life becomes a base.',
      body:
          'The Compound shows 8 core stats as buildings. When a stat levels up, its building upgrades. Tap any building to inspect it or create missions for that domain.',
      bullets: [
        'Buildings = your core stats.',
        'Bigger buildings mean higher tiers.',
        'Ghost buildings show pace targets.',
      ],
      color: OperatorPalette.torchOrange,
    ),
    _WalkthroughPage(
      icon: Icons.bolt_outlined,
      label: 'MISSIONS & XP',
      title: 'Actions build the base.',
      body:
          'Missions are the core loop. Create a mission, finish it, and XP goes into that stat. XP raises levels, levels raise tiers, and tiers change the Compound art.',
      bullets: [
        'Trivial, standard, hard, boss, and recovery missions have different XP.',
        'Pending missions show alert beacons on buildings.',
        'Completing a mission immediately updates progress.',
      ],
      color: OperatorPalette.successGreen,
    ),
    _WalkthroughPage(
      icon: Icons.route_outlined,
      label: 'SYSTEMS',
      title: 'Use tools only when they help.',
      body:
          'Journal is for reflection, Sleep is for recovery, Roadmap is for planning, and Campaigns help you focus a season. They live under quick actions so the app stays clean.',
      bullets: [
        'Journal wins and lessons.',
        'Track sleep to protect Vitality.',
        'Use Campaigns when you need focus.',
      ],
      color: OperatorPalette.hologramBlue,
    ),
    _WalkthroughPage(
      icon: Icons.settings_outlined,
      label: 'PERSONAL MODE',
      title: 'You can keep it simple.',
      body:
          'Personal Mode stores your data locally on-device. Supabase sign-in is optional. Settings lets you replay this walkthrough, see your mode, and sign out.',
      bullets: [
        'Personal Mode works without Supabase.',
        'AI currently falls back safely when no local model is configured.',
        'Replay this guide anytime from Settings.',
      ],
      color: OperatorPalette.warningAmber,
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await setOperatorOnboardingComplete(true);
    if (!mounted) return;

    final destination = widget.destination;
    if (destination == null) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: destination,
        ),
      ),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_index];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _WalkthroughBackground()),
          Positioned.fill(child: CustomPaint(painter: _WalkthroughGridPainter(current.color))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('OPERATOR BOOTCAMP', style: OperatorTextStyles.overline),
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) => _WalkthroughPageView(page: _pages[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == _index
                                  ? current.color
                                  : OperatorPalette.borderDim,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          if (_index > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                ),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back'),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _next,
                              icon: Icon(_isLast ? Icons.check_circle_outline : Icons.arrow_forward),
                              label: Text(_isLast ? 'Enter App' : 'Next'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkthroughPage {
  final IconData icon;
  final String label;
  final String title;
  final String body;
  final List<String> bullets;
  final Color color;

  const _WalkthroughPage({
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
    required this.bullets,
    required this.color,
  });
}

class _WalkthroughPageView extends StatelessWidget {
  final _WalkthroughPage page;

  const _WalkthroughPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WalkthroughIcon(page: page),
              const SizedBox(height: 24),
              Text(page.label, textAlign: TextAlign.center, style: OperatorTextStyles.overline),
              const SizedBox(height: 10),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: OperatorPalette.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(page.body, textAlign: TextAlign.center, style: OperatorTextStyles.body),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: OperatorPalette.panelDark.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: page.color.withValues(alpha: 0.26)),
                ),
                child: Column(
                  children: page.bullets
                      .map(
                        (bullet) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: page.color),
                              const SizedBox(width: 10),
                              Expanded(child: Text(bullet, style: OperatorTextStyles.body)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalkthroughIcon extends StatelessWidget {
  final _WalkthroughPage page;

  const _WalkthroughIcon({required this.page});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.88, end: 1),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [page.color.withValues(alpha: 0.90), page.color.withValues(alpha: 0.16)],
          ),
          border: Border.all(color: page.color.withValues(alpha: 0.55), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: page.color.withValues(alpha: 0.24),
              blurRadius: 38,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Icon(page.icon, size: 56, color: OperatorPalette.voidBlack),
      ),
    );
  }
}

class _WalkthroughBackground extends StatelessWidget {
  const _WalkthroughBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OperatorPalette.voidBlack,
            OperatorPalette.nightNavy,
            Color(0xFF071109),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughGridPainter extends CustomPainter {
  final Color color;

  const _WalkthroughGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.2, -0.35),
        radius: 1.2,
        colors: [color.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.035);
    const spacing = 42.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), linePaint);
    }
    for (double x = 0; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WalkthroughGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
