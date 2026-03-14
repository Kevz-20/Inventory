# Seed Bootstrap Notes

## What The Seed Migration Adds

The migration `supabase/migrations/003_seed_and_profile_bootstrap.sql` adds three things:

1. `handle_new_user()`
   - automatically creates a `public.profiles` row when a new Supabase Auth user is created

2. demo organization seed
   - creates `SLPA-DEMO-001`

3. `seed_membership_for_user(...)`
   - helper function to assign a user to an organization with a role

## Why This Matters

The backend now has:

- schema
- row-level security
- profile bootstrap

That means the next step can move into actual client integration instead of only backend planning.

## Example Use

After creating a real auth user in Supabase, an admin can assign that user to the demo SLPA by calling:

```sql
select public.seed_membership_for_user(
  'USER-UUID-HERE',
  'SLPA-DEMO-001',
  'slpa_admin'
);
```

## Next Task

The next practical coding task is on the Flutter side:

- initialize Supabase
- replace local-only signup/login
- fetch profile plus organization membership after authentication
