# Operator OS — Phase 0 Setup

## 1. Supabase Project Setup (tiny steps)

1. Go to [supabase.com](https://supabase.com) and create a new project.
2. Wait for the project to finish initializing.
3. In the left sidebar, click **SQL Editor**.
4. Click **New query**.
5. Copy the **entire contents** of `supabase/schema.sql` from this repo and paste it into the editor.
6. Click **Run**. This creates all tables and RLS policies.
7. In the left sidebar, click **Project Settings** → **API**.
8. Copy the `URL` and `anon public` key.
9. Open `lib/core/constants.dart` and replace:
   - `https://your-project.supabase.co` with your URL.
   - `your-anon-key` with your anon key.

## 2. Enable Auth Providers (tiny steps)

1. In Supabase sidebar, go to **Authentication** → **Providers**.
2. Find **Google** and click it.
3. Toggle **Enabled** to ON.
4. If you want native Google Sign-In (optional):
   - Go to Google Cloud Console.
   - Create an OAuth 2.0 Web client ID and Android client ID.
   - Add your app’s SHA-1 fingerprint to the Android client ID.
   - Copy the **Web Client ID** and paste it into Supabase Google provider settings under **Client ID**.
5. Find **Email** provider and toggle **Enabled** to ON (for magic-link fallback).

## 3. Run code generation (tiny steps)

Because this project uses Drift and Riverpod codegen, you must generate `.g.dart` files before building.

```bash
cd operator_os
dart run build_runner build --delete-conflicting-outputs
```

If you later change Drift tables or Riverpod providers, re-run the same command.

## 4. Android build notes (tiny steps)

- The project is pre-configured for **AGP 9.1.1**, **Gradle 9.5.1**, and **Kotlin 2.2.10**.
- The `kotlin-android` Gradle plugin is **intentionally omitted** because AGP 9 has built-in Kotlin support.
- If you see Gradle version errors, ensure your local Gradle wrapper matches the URL in `android/gradle/wrapper/gradle-wrapper.properties`.
- Set `namespace = "com.example.operator_os"` and `compileSdk = 35` explicitly in `android/app/build.gradle.kts`.

## 5. Run the app (tiny steps)

```bash
flutter pub get
flutter run
```

- First launch creates an empty Drift SQLite database at `operator_os_db`.
- The app starts at a **Splash** screen, checks Supabase session, and routes to **Sign-In** or **Home**.
- Sync runs automatically on app foreground/background. Until Supabase credentials are filled in, sync silently no-ops.

## 6. Verify Phase 0

- [ ] `flutter pub get` resolves with zero version conflicts.
- [ ] App builds on Android debug with **zero Gradle / Kotlin errors**.
- [ ] Google Sign-In button opens the OAuth flow and returns to the app.
- [ ] Magic-link email input sends an OTP link.
- [ ] After sign-in, you land on the **Home placeholder** screen.
- [ ] Sign-out and sign back in with the **same account** — the same `user_id` is preserved in Supabase and local DB rows.
