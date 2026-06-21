# Operator OS Release / Compliance Checklist

This is a practical checklist before distributing Operator OS publicly. It is not legal advice.

## Privacy / data safety

- [ ] Publish a public web Privacy Policy URL. The in-app Privacy Policy is not enough for Google Play/App Store.
- [ ] Keep the public Privacy Policy consistent with the in-app Privacy Policy.
- [ ] Complete Google Play Data Safety accurately.
- [ ] Complete Apple App Privacy accurately if releasing on iOS.
- [ ] Disclose Supabase if authentication/sync is enabled.
- [ ] Disclose any AI provider/model service if remote AI is enabled.
- [ ] Disclose notifications/reminders if used.
- [ ] Avoid collecting highly sensitive data unless you have a real compliance plan.

## Account / deletion

- [ ] If online accounts are enabled, provide account deletion instructions or an in-app/web deletion flow.
- [ ] Explain that local data clearing does not automatically delete remote Supabase data.
- [ ] Add a support/contact email before public launch.

## AI safety

- [ ] Keep AI outputs framed as drafts/insights, not professional advice.
- [ ] Warn users not to enter secrets, medical records, payment details, or legal/financially sensitive data.
- [ ] If using external AI APIs later, update privacy disclosures and app store forms.

## Medical / financial / legal disclaimers

- [ ] Do not market the app as medical, mental health, financial, legal, or guaranteed productivity advice.
- [ ] Keep terms clear that users are responsible for actions and decisions.
- [ ] Add crisis/emergency disclaimers where relevant.

## Permissions

- [ ] Verify Android notification permission behavior and rationale.
- [ ] Verify internet permission is justified by auth/sync.
- [ ] Remove unused permissions before public release.

## Third-party SDK/dependencies

- [ ] Re-run dependency review before release.
- [ ] Confirm no plugin warning remains for Kotlin Gradle Plugin / AGP compatibility.
- [ ] Verify all SDKs used are disclosed in app store forms.

## Build / branding

- [ ] Confirm launcher icon appears correctly after uninstall/reinstall.
- [ ] Confirm app label is "Operator OS".
- [ ] Confirm APK output is named "Operator OS.apk" if using build.ps1.
- [ ] Run `flutter clean`, `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, and tests before release.

## Final reminder

This repo now includes in-app Privacy Policy, Terms & Safety, Data Safety notes, legal acknowledgement on login, local data clearing, and sign-out redirection. Public app store release still requires external disclosures and contact/deletion processes.
