# Supabase Auth Migration

## Goal

The frontend now uses Supabase directly only for authentication. App data and AI/RAG flows should go through the UpHeal backend instead of Firebase/Firestore.

## What Changed

### Dependencies

- Removed frontend Firebase Auth/Core usage.
- Removed direct Firestore dependency.
- Added `supabase_flutter`.

### Auth Bootstrap

`lib/main.dart` initializes Supabase through:

```dart
await SupabaseAuthService.initialize();
```

The app reads Supabase config from Dart defines:

```bash
--dart-define=SUPABASE_URL=https://gcxxmjptbyvlabqzcprv.supabase.co
--dart-define=SUPABASE_ANON_KEY=<your-supabase-anon-key>
```

`SUPABASE_URL` has a project default. `SUPABASE_ANON_KEY` must be supplied at build/run time.

### Auth Service

`lib/services/supabase_auth_service.dart` owns:

- sign in with email/password
- sign up with email/password
- current user id
- current access token
- auth state changes
- logout
- password reset

### App Auth State

`lib/models/auth_model.dart` now wraps `SupabaseAuthService`.

The existing login/signup screens continue to use `AuthModel`, so the UI did not need a full rewrite.

### RAG API Token

`lib/screens/gad_phq_form_screen.dart` now sends:

```http
Authorization: Bearer <supabase-access-token>
```

to:

```http
POST /api/assess
```

This matches the backend Supabase JWT validator.

### Removed Direct Firebase/Firestore Usage

- `lib/firebase_options.dart` was removed.
- `lib/services/firebase_auth_service.dart` was removed.
- Assessment completion and results are stored locally by Supabase user id.
- Streak persistence is local until the backend exposes a streak endpoint.
- Mood remote sync is a backend placeholder until the backend exposes mood endpoints.

## Remaining Backend Work

To fully satisfy "frontend depends on backend except auth", the backend should expose endpoints for:

- mood entries
- streak state
- assessment history/status if local-only storage is not enough

Until then, those features remain offline/local-first instead of using Firebase directly.
