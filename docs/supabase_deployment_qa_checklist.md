# Supabase Deployment And QA Checklist

## Goal

Use this checklist to move the app from local development into a real
Supabase-backed integration test on emulator or device.

This checklist assumes the current Flutter app is:

- offline-first
- SQLite-backed locally
- Supabase-enabled through `--dart-define`
- using the sync queue and diagnostics flow already added in the app

Companion runbook:

- `docs/supabase_qa_runbook.md`

## Phase 1: Backend Apply Order

Apply migrations in this order:

1. `supabase/migrations/001_initial_foundation.sql`
2. `supabase/migrations/002_rls_policies.sql`
3. `supabase/migrations/003_seed_and_profile_bootstrap.sql`
4. `supabase/migrations/004_external_sync_keys.sql`

Confirm after migration:

- all tables exist
- `external_local_uuid` exists on syncable backend tables
- RLS is enabled
- helper functions for organization access exist
- profile bootstrap trigger exists

## Phase 2: Supabase Project Setup

Create or confirm:

- one Supabase project
- one test organization
- one test user
- one test membership for that user
- correct anon key for the Flutter app

Minimum checks:

- auth signup/signin works
- inserted auth user creates a `public.profiles` row
- seeded or assigned membership points to the correct organization

## Phase 3: Flutter App Configuration

Run the app with:

```powershell
flutter run ^
  --dart-define=SUPABASE_URL=your-project-url ^
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Confirm:

- Supabase initializes without crash
- login/create-account uses backend mode
- selected organization is persisted locally
- home screen shows organization context

## Phase 4: Core Manual Test Scenarios

Run these in order.

### Product Sync

1. create a product while online
2. confirm backend `products` row exists
3. confirm local `server_id` and `last_synced_at` are populated
4. edit the product
5. confirm backend row updates without duplication

### Customer Sync

1. create a customer while online
2. confirm backend `customers` row exists
3. confirm `external_local_uuid` is written
4. edit the customer
5. confirm local and backend stay linked

### Offline Queue

1. disable internet
2. create a product
3. create a customer
4. confirm `sync_status` is pending locally
5. open `Sync Diagnostics`
6. confirm pending/local state is visible
7. restore internet
8. trigger sync or wait for resume/background sync
9. confirm records become synced

### Cash Sale Sync

1. create a cash sale
2. confirm backend `sales` row exists
3. confirm backend `sale_items` rows exist
4. confirm local `sales` and `sale_item` rows store `server_id`

### Credit Sale Sync

1. create a credit sale
2. confirm backend `sales` row exists
3. confirm backend `receivables` row exists
4. confirm local `sales_credit` rows are marked synced

### Customer Payment Sync

1. record a customer payment
2. confirm backend `receivable_payments` row exists
3. confirm backend `receivables.remaining_amount` decreases
4. confirm local `customer_payment` row is marked synced

## Phase 5: Failure And Recovery Scenarios

### Retry Flow

1. create data while backend is unreachable
2. confirm queue entry appears in `Sync History`
3. restore backend access
4. use `Retry` or `Sync now`
5. confirm queue job completes

### Conflict Flow

1. sync a record once
2. change the backend row manually
3. change the local row again
4. trigger sync
5. confirm a conflict appears
6. confirm diagnostics shows the queue failure
7. confirm `Force overwrite` works only when intentionally used

### Organization Safety

1. create queued data under one organization
2. switch to another organization
3. confirm the queued job is not replayed under the wrong org
4. confirm queue history and diagnostics stay org-scoped

## Phase 6: Data Validation Checks

For backend records, verify:

- `organization_id` is correct
- `created_by_user_id` and `updated_by_user_id` are correct
- `external_local_uuid` is present where expected
- retries do not create duplicates
- soft-deletes write `deleted_at` instead of hard delete

For local records, verify:

- `local_uuid` exists
- `server_id` is filled after sync
- `sync_status` changes as expected
- `last_synced_at` updates after successful sync

## Phase 7: Admin Monitoring And Reports QA

These checks validate the PDO/admin paths, not only the SLPA operational flow.

### Admin Monitoring

1. sign in as a user with `pdo_consultant`, `system_admin`, or `slpa_admin`
2. open `Settings`
3. confirm `Admin Monitoring` is visible
4. open `Admin Monitoring`
5. confirm organization cards load for accessible organizations
6. confirm each card shows:
   - member count
   - audit event count
   - latest audit action/entity
7. use `Audit`
8. confirm the audit log opens filtered to the selected organization
9. use `Details`
10. confirm the organization detail screen opens for the selected organization

### Organization Detail

1. confirm organization identity fields are correct
2. confirm `Monitoring Summary` matches backend activity
3. confirm `Access Breakdown` shows role and status counts
4. confirm member list loads
5. test:
   - search by member name
   - filter by role
   - filter by status
6. confirm `Recent Activity` loads latest audit events
7. from a recent activity item, open:
   - `Diagnostics`
   - `Queue`
   - `Audit Log`
8. confirm each route is filtered to the correct organization/record when applicable

### Admin Reports

1. from organization detail, open `Reports`
2. confirm `Admin Reports` opens for the selected organization
3. confirm these sections load:
   - organization identity
   - reporting snapshot
   - financial summary
   - recent backend activity
   - export section
4. confirm financial summary values are reasonable against backend rows:
   - total sales
   - collected payments
   - outstanding receivables
   - sales count
   - open receivables count
5. use `Copy Snapshot`
6. confirm visible success feedback appears
7. use `Open Audit Log`
8. confirm org-filtered audit log opens
9. from a recent backend activity item, open:
   - `Diagnostics`
   - `Queue`
10. confirm filtered routes match the target record

## Phase 8: Pre-Deployment Readiness

Do not treat the app as deployment-ready until these are true:

- `flutter analyze` passes
- `flutter test` passes
- sync service tests pass
- diagnostics widget tests pass
- manual online/offline scenarios pass
- admin monitoring scenarios pass
- admin reports scenarios pass
- no duplicate backend rows appear on retry
- RLS blocks wrong-organization access

## Recommended Evidence To Capture

Keep simple QA evidence for each scenario:

- screenshot of local diagnostics
- screenshot of sync history
- screenshot of admin monitoring
- screenshot of admin reports
- screenshot or SQL result of backend row
- note of expected and actual result

Recommended working template:

- `docs/qa_evidence_template.md`

## Immediate Next Work After QA

Once this checklist is passing, the next engineering priorities should be:

1. build file-based admin exports if PDO/admin handoff needs CSV or PDF
2. start extracting the admin flow into a dedicated web-first portal
3. document production backup and lost-device recovery workflow
4. expand backend financial/reporting aggregates beyond the current summary cards
