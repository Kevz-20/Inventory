# RLS Strategy

## What This Adds

The migration `supabase/migrations/002_rls_policies.sql` turns on row-level security and adds access policies for the current backend foundation tables.

## Access Model

The policies use organization membership plus role checks.

### Roles

- `slpa_member`
- `slpa_admin`
- `pdo_consultant`
- `system_admin`

### Access Rules

- `slpa_member`
  - can read records for organizations they belong to
  - can create operational records like sales and expenses for their organization
  - cannot manage memberships or organization settings

- `slpa_admin`
  - can read and manage records for their organization
  - can manage memberships inside their organization

- `pdo_consultant`
  - currently treated as an elevated org-level role
  - can read and manage records for organizations they are assigned to

- `system_admin`
  - can access everything across organizations

## Helper Functions

The migration adds helper functions to keep policies readable:

- `current_profile_id()`
- `is_system_admin()`
- `has_org_role(target_org, allowed_roles)`
- `can_access_org(target_org)`
- `can_manage_org(target_org)`

## Important Note

This is a solid first pass, but it is still a foundation only.

The next policy work should eventually separate:

- read-only PDO access vs edit access
- service-role/internal backend access
- file storage access rules
- more granular module permissions if needed

## Next Build Step

After these RLS policies, the next practical step is:

1. add seed data for one organization and one admin membership
2. define the auth/profile bootstrap flow
3. connect the Flutter login/account system to Supabase auth and profiles
