# Flutter Auth Migration

## Purpose

This document defines how the current Flutter login and account flow should move from local-only identity to Supabase Auth plus server-backed profiles and memberships.

## Current State

The app currently uses:

- local SQLite `account` table
- local PIN-based login
- `SharedPreferences` for current mobile number and full name

This is not enough for:

- multi-device access
- recovery after phone loss
- centralized access control
- PDO monitoring

## Target Auth Model

### Source Of Truth

- authentication: `auth.users`
- user details: `public.profiles`
- access and role: `public.organization_memberships`

### Signup Flow

1. user signs up with email and password in Supabase Auth
2. app sends metadata:
   - `first_name`
   - `middle_name`
   - `last_name`
   - `mobile_number`
3. database trigger `handle_new_user()` creates a row in `public.profiles`
4. admin or bootstrap process assigns the user to an organization with a role

### Login Flow

1. user signs in with Supabase Auth
2. app fetches:
   - `profile`
   - active `organization_memberships`
3. app stores only session and lightweight cached identity locally
4. local SQLite becomes operational cache, not the primary identity store

## Flutter Changes Required

### Replace local-only identity assumptions

Current files that will need refactor first:

- `lib/models/account_model.dart`
- `lib/repositories/login_repository.dart`
- `lib/repositories/create_account_repository.dart`
- `lib/repositories/account_repository.dart`
- `lib/view_models/login_view_model.dart`
- `lib/view_models/create_account_view_model.dart`

### Add new concepts

The Flutter app should introduce models for:

- `AppUserProfile`
- `OrganizationMembership`
- `AuthenticatedSession`

### Local storage changes

`SharedPreferences` should store only:

- last selected organization id
- cached display name
- local sync settings

It should not remain the primary source for authorization decisions.

## Recommended Migration Sequence

1. add Supabase Flutter dependency and environment config
2. implement sign up and sign in against Supabase Auth
3. fetch `profiles` and `organization_memberships`
4. keep current SQLite tables for business data cache
5. stop creating local-only `account` records for new users
6. later migrate existing local account data to server-backed profiles

## Short-Term Compromise

During transition, the app can still keep local PIN or biometric unlock for convenience, but only after a valid Supabase-authenticated session has been established.

This means:

- primary identity = backend auth
- optional quick unlock = local device convenience feature

## Next Coding Step

After this bootstrap work, the next implementation task in Flutter should be:

1. add Supabase client initialization
2. refactor signup/login repositories to call Supabase Auth
3. fetch the current profile and memberships after login
4. phase out direct dependency on local `account` for authentication
