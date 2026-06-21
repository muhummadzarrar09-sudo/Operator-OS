import 'package:flutter/material.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/widgets/operator_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String operatorLegalAcceptedPrefsKey = 'operator_os_legal_accepted_v1';

Future<bool> hasAcceptedOperatorLegalTerms() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(operatorLegalAcceptedPrefsKey) ?? false;
}

Future<void> setOperatorLegalAccepted(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(operatorLegalAcceptedPrefsKey, value);
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Privacy Policy',
      label: 'PRIVACY',
      icon: Icons.privacy_tip_outlined,
      accent: OperatorPalette.hologramBlue,
      sections: [
        _LegalSection(
          title: 'Effective date',
          body: 'June 21, 2026. This in-app policy explains how Operator OS handles data inside the app.',
        ),
        _LegalSection(
          title: 'Short version',
          body:
              'Operator OS is designed to be local-first. Your stats, missions, journal entries, roadmap, sleep logs, boss days, and memory archive are stored in the local app database on your device. Supabase sign-in/sync is optional and only applies if you configure/sign in with a Supabase-backed account.',
        ),
        _LegalSection(
          title: 'Data you create',
          body:
              'The app may store content you enter, including missions, journal entries, sleep logs, roadmap days, campaign choices, boss reviews, AI prompts, generated insights, embeddings, and XP/stat progress. Do not enter secrets, passwords, government IDs, medical records, payment card data, or anything you would not want stored locally or synced if online mode is configured.',
        ),
        _LegalSection(
          title: 'Account and authentication data',
          body:
              'If you use Personal Mode, the app uses a local operator profile on this device. If you use Supabase authentication, Supabase may process account identifiers such as user ID, email, OAuth provider identifiers, session tokens, and related authentication metadata according to your Supabase project settings and Supabase policies.',
        ),
        _LegalSection(
          title: 'Local storage',
          body:
              'Local data is stored using the app database and device preferences. Anyone with access to your unlocked device or device backups may be able to access app data depending on your device security and backup settings.',
        ),
        _LegalSection(
          title: 'Optional sync',
          body:
              'If Supabase credentials are configured and you are signed in, the app may sync supported local rows to your Supabase backend and pull remote rows back to the device. If Supabase credentials are placeholders or you use Personal Mode, sync is not required for normal app use.',
        ),
        _LegalSection(
          title: 'AI and embeddings',
          body:
              'The current app can run with mock/fallback AI behavior. If a future local model or remote model is connected, prompts, journal content, entries, and generated embeddings may be processed by that model or service depending on configuration. Review model/provider terms before enabling external AI services.',
        ),
        _LegalSection(
          title: 'Permissions',
          body:
              'The app may request notification permissions for reminders and uses internet access for authentication/sync if configured. Notification permissions can be disabled in your device settings.',
        ),
        _LegalSection(
          title: 'Data deletion',
          body:
              'You can clear local data for your current user from Settings. For Supabase/online data, deletion depends on your Supabase backend configuration. If this app is distributed publicly, provide a public account/data deletion contact or web flow as required by app store policies.',
        ),
        _LegalSection(
          title: 'Children',
          body:
              'Operator OS is not intended for children under 13. Do not knowingly collect or enter data from children unless your legal requirements and guardian consent obligations are satisfied.',
        ),
        _LegalSection(
          title: 'Changes',
          body:
              'This policy may be updated as features change. For public distribution, publish a web-accessible copy of the privacy policy and keep it consistent with the in-app version.',
        ),
        _LegalSection(
          title: 'Important store compliance note',
          body:
              'An in-app privacy policy is helpful, but Google Play/App Store may also require a public privacy policy URL and accurate Data Safety/App Privacy disclosures. This screen is not legal advice.',
        ),
      ],
    );
  }
}

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Terms & Safety',
      label: 'TERMS',
      icon: Icons.gavel_outlined,
      accent: OperatorPalette.parchmentGold,
      sections: [
        _LegalSection(
          title: 'Use at your own discretion',
          body:
              'Operator OS is a productivity and self-tracking tool. It does not guarantee results, income, health outcomes, academic outcomes, or personal transformation.',
        ),
        _LegalSection(
          title: 'Not professional advice',
          body:
              'Content in the app, including AI-generated text, reminders, missions, insights, and walkthrough guidance, is not medical, mental health, legal, financial, tax, fitness, or professional advice. Consult qualified professionals for decisions that require expertise.',
        ),
        _LegalSection(
          title: 'User responsibility',
          body:
              'You are responsible for the content you enter, the missions you create, the actions you take, and your compliance with laws, school/work policies, platform rules, and third-party service terms.',
        ),
        _LegalSection(
          title: 'No dangerous use',
          body:
              'Do not use the app to plan harmful, illegal, abusive, exploitative, or unsafe activity. Do not rely on the app for emergencies. If you are in danger or experiencing a crisis, contact local emergency services or appropriate support immediately.',
        ),
        _LegalSection(
          title: 'AI limitations',
          body:
              'AI outputs can be inaccurate, incomplete, outdated, biased, or inappropriate. Treat AI output as a draft or reflection aid, not as truth. Verify important information before acting on it.',
        ),
        _LegalSection(
          title: 'Data backups',
          body:
              'Local data can be lost if the app is uninstalled, device storage is cleared, the database is corrupted, or sync is misconfigured. Keep your own backups for important information.',
        ),
        _LegalSection(
          title: 'Distribution responsibilities',
          body:
              'If you publish this app, you are responsible for app store compliance, privacy disclosures, account deletion requirements, support contact details, content ratings, permissions declarations, and third-party service terms.',
        ),
      ],
    );
  }
}

class DataSafetyScreen extends StatelessWidget {
  const DataSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Data Safety Notes',
      label: 'DATA SAFETY',
      icon: Icons.security_outlined,
      accent: OperatorPalette.warningAmber,
      sections: [
        _LegalSection(
          title: 'Data categories the app may contain',
          body:
              'User-generated content, productivity data, journal/reflection text, sleep logs, roadmap plans, mission completion history, XP/stat progress, local identifiers, authentication identifiers if online mode is used, and optional AI embeddings/outputs.',
        ),
        _LegalSection(
          title: 'Sensitive data warning',
          body:
              'The app is not designed to collect highly sensitive information. Avoid entering health records, biometric data, financial account details, passwords, legal documents, or information about other people without consent.',
        ),
        _LegalSection(
          title: 'Third-party services',
          body:
              'Supabase may be used for authentication and sync if configured. Device notification services may display reminders. Future AI providers or local model packages may introduce additional data flows. Disclose only the services you actually enable in production.',
        ),
        _LegalSection(
          title: 'App store checklist',
          body:
              'Before public release: publish a privacy policy URL, complete Data Safety/App Privacy forms accurately, provide support/contact details, provide account/data deletion instructions if accounts are supported, verify notification permission copy, and confirm all third-party SDK disclosures.',
        ),
      ],
    );
  }
}

class _LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String label;
  final IconData icon;
  final Color accent;
  final List<_LegalSection> sections;

  const _LegalDocumentScreen({
    required this.title,
    required this.label,
    required this.icon,
    required this.accent,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OperatorPalette.voidBlack,
                    OperatorPalette.nightNavy,
                    Color(0xFF0B111C),
                  ],
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              OperatorCard(
                icon: icon,
                accentColor: accent,
                label: label,
                title: title,
                body:
                    'Read this before relying on the app for personal tracking, AI insights, sync, or public distribution.',
              ),
              const SizedBox(height: 14),
              ...sections.map((section) => _LegalSectionCard(section: section, accent: accent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection({required this.title, required this.body});
}

class _LegalSectionCard extends StatelessWidget {
  final _LegalSection section;
  final Color accent;

  const _LegalSectionCard({required this.section, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: OperatorPalette.panelDark.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title.toUpperCase(), style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          Text(section.body, style: OperatorTextStyles.body),
        ],
      ),
    );
  }
}
