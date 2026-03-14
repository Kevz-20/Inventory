# Supabase QA Runbook

Use this runbook for the first real backend/device validation pass.

It is meant to be followed in order together with:

- `docs/supabase_deployment_qa_checklist.md`
- `docs/qa_evidence_template.md`
- `docs/seed_bootstrap_notes.md`

---

## 1. Backend Apply Order

Apply these migrations in order:

1. `supabase/migrations/001_initial_foundation.sql`
2. `supabase/migrations/002_rls_policies.sql`
3. `supabase/migrations/003_seed_and_profile_bootstrap.sql`
4. `supabase/migrations/004_external_sync_keys.sql`

After apply, confirm these backend tables exist:

- `organizations`
- `profiles`
- `organization_memberships`
- `products`
- `customers`
- `sales`
- `sale_items`
- `receivables`
- `receivable_payments`
- `audit_logs`

Quick check:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

---

## 2. Bootstrap Test Data

### Create test users

Create at least:

- 1 PDO/admin user
- 1 SLPA user

Then verify `public.profiles` rows were created automatically:

```sql
select id, mobile_number, first_name, last_name, status
from public.profiles
order by created_at desc;
```

### Assign memberships

Use the helper from `003_seed_and_profile_bootstrap.sql`:

```sql
select public.seed_membership_for_user(
  'USER-UUID-HERE',
  'SLPA-DEMO-001',
  'pdo_consultant'
);

select public.seed_membership_for_user(
  'USER-UUID-HERE',
  'SLPA-DEMO-001',
  'slpa_admin'
);
```

Verify:

```sql
select
  m.id,
  m.organization_id,
  o.code as organization_code,
  m.user_id,
  r.code as role_code,
  m.status
from public.organization_memberships m
join public.organizations o on o.id = m.organization_id
join public.roles r on r.id = m.role_id
order by m.created_at desc;
```

---

## 3. Run The Flutter App

Start the app with real backend values:

```powershell
flutter run ^
  --dart-define=SUPABASE_URL=your-project-url ^
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Initial checks:

- app launches without Supabase init error
- login works
- selected organization is visible on Home
- Settings shows:
  - `Sync History`
  - `Sync Diagnostics`
  - `Audit Log`
  - `Admin Monitoring` for admin/PDO roles

---

## 4. Execute Core Sync Scenarios

Follow the detailed scenarios in:

- `docs/supabase_deployment_qa_checklist.md`

Recommended order:

1. Product Sync
2. Customer Sync
3. Offline Queue
4. Cash Sale Sync
5. Credit Sale Sync
6. Customer Payment Sync
7. Retry Flow
8. Conflict Flow
9. Organization Safety

For each scenario:

- record evidence in `docs/qa_evidence_template.md`
- capture one UI screenshot
- capture one backend query result

---

## 5. Backend Validation Queries

### Products

```sql
select id, organization_id, name, external_local_uuid, updated_at
from public.products
order by updated_at desc
limit 20;
```

### Customers

```sql
select id, organization_id, first_name, last_name, external_local_uuid, updated_at
from public.customers
order by updated_at desc
limit 20;
```

### Sales

```sql
select id, organization_id, sale_type, total_amount, external_local_uuid, created_at
from public.sales
order by created_at desc
limit 20;
```

### Receivables

```sql
select id, organization_id, sale_id, customer_id, original_amount, remaining_amount, status, external_local_uuid
from public.receivables
order by created_at desc
limit 20;
```

### Receivable Payments

```sql
select id, organization_id, receivable_id, amount, paid_at, external_local_uuid
from public.receivable_payments
order by paid_at desc
limit 20;
```

### Audit Logs

```sql
select id, organization_id, action, entity_type, entity_id, occurred_at
from public.audit_logs
order by occurred_at desc
limit 30;
```

---

## 6. Admin Monitoring And Reports Pass

Sign in as the PDO/admin user and check:

### Admin Monitoring

- organization cards load
- member counts are correct
- audit counts are reasonable
- latest audit action/entity looks correct

### Organization Detail

- organization identity is correct
- access breakdown matches memberships
- member list and filters work
- recent activity loads

### Admin Reports

- reporting snapshot loads
- financial summary loads
- recent backend activity loads
- `Copy Snapshot` shows success status
- `Save CSV` works
- `Save PDF` works

Validate financial totals by comparing UI against:

- `public.sales`
- `public.receivables`
- `public.receivable_payments`

---

## 7. RLS And Tenant Safety Checks

Validate that users only see data for their allowed organizations.

Manual checks:

- sign in as SLPA user
- confirm admin-only paths are hidden if role does not permit them
- confirm queue, diagnostics, audit log, and admin screens stay within correct org scope

If you have a second organization, also verify:

- one org’s queued records do not replay under another org
- admin cards and reports remain organization-specific

---

## 8. Exit Criteria

Mark the QA pass successful only when:

- all checklist scenarios were executed
- no duplicate backend rows were produced by retry/reconnect
- conflicts were surfaced correctly
- org isolation was preserved
- admin monitoring values matched backend rows
- admin report totals matched backend rows
- CSV/PDF export opened successfully on the test device

Then summarize results in:

- `docs/qa_evidence_template.md`
