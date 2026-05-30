# RAG JWT Integration Notes

## Problem

The backend requires `Authorization: Bearer <jwt>` for `POST /api/assess`.

In this frontend checkout, `lib/services/upheal_api.dart` was only sending:

```http
Content-Type: application/json
```

That means this frontend could reproduce the backend error:

```json
{"detail":"Missing authorization header"}
```

## Changes Made

### `lib/services/upheal_api.dart`

- Added an optional `authToken` parameter to `UphealApi.assess(...)`.
- Added `Authorization: Bearer <authToken>` when a token is provided.

### `lib/screens/gad_phq_form_screen.dart`

- Reads the current Supabase auth state before submitting the RAG assessment.
- Uses the Supabase user id as `user_id`.
- Passes the Supabase access token into `UphealApi.assess(...)`.

## Important Backend Compatibility Note

This Flutter app now uses Supabase Auth.

The backend issue report describes Supabase JWTs, and the backend auth middleware currently supports:

- Supabase HS256 tokens
- Supabase ES256 tokens verified through Supabase JWKS

The RAG request now sends the Supabase access token, so `/api/assess` should match the backend validator.

## Next Verification Step

Run the Flutter assessment flow while logged in with Supabase and confirm the request contains:

```http
Authorization: Bearer <supabase-access-token>
```
