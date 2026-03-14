# Supabase Next Steps

## What This Adds

The initial schema in `supabase/migrations/001_initial_foundation.sql` creates the first deployable backend foundation for:

- SLPA organizations
- user profiles linked to Supabase Auth
- roles
- organization memberships
- products
- customers
- sales
- receivables
- expenses
- audit logs

## Why This Is The Right First Step

The current Flutter app is local SQLite only. Before changing the app, the project needs a central data model that supports:

- many SLPAs
- many users
- role-based access
- monitoring by PDO or staff
- auditability

This schema establishes that foundation.

## Important Design Decisions

### Identity

- authentication lives in `auth.users`
- app-specific user details live in `public.profiles`

### Multi-tenancy

- every business record includes `organization_id`
- this is how SLPA data stays separated

### Accountability

- business tables include creator and updater user references
- `audit_logs` records important actions for transparency

### Soft deletion

- key business tables include `deleted_at`
- records can be hidden without losing the history

## What Still Needs To Be Added

- row-level security policies
- file storage metadata table
- payables and owner installments
- inventory movement ledger
- notification tables
- admin portal

## Sync Idempotency

The backend now also needs explicit client sync keys so mobile retries can be
idempotent across reconnects, app restarts, and interrupted sync jobs.

Use `external_local_uuid` on:

- `products`
- `customers`
- `sales`
- `sale_items`
- `receivables`
- `receivable_payments`

The migration `supabase/migrations/004_external_sync_keys.sql` adds those
columns plus unique indexes so one local record cannot create duplicate backend
records for the same organization.

## Next Build Step

After this schema, the next implementation step should be:

1. deploy `004_external_sync_keys.sql`
2. update the Flutter sync service to write and query `external_local_uuid`
3. reduce heuristic matching by name/phone/date wherever external sync keys exist
4. add backend-side audit logging for sync writes

## Current Validation Step

The project now also has a concrete integration checklist for the next phase:

- `docs/supabase_deployment_qa_checklist.md`

Use that document to:

1. apply migrations in the correct order
2. configure the Flutter app against a real Supabase project
3. run manual offline/online sync scenarios
4. verify admin monitoring and admin reports with real organization data
5. verify RLS, idempotency, and organization safety before deployment
