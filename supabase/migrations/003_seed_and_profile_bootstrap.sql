create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta_first_name text;
  meta_middle_name text;
  meta_last_name text;
  meta_mobile_number text;
begin
  meta_first_name := nullif(trim(coalesce(new.raw_user_meta_data ->> 'first_name', '')), '');
  meta_middle_name := nullif(trim(coalesce(new.raw_user_meta_data ->> 'middle_name', '')), '');
  meta_last_name := nullif(trim(coalesce(new.raw_user_meta_data ->> 'last_name', '')), '');
  meta_mobile_number := nullif(trim(coalesce(new.raw_user_meta_data ->> 'mobile_number', '')), '');

  insert into public.profiles (
    id,
    mobile_number,
    first_name,
    middle_name,
    last_name
  )
  values (
    new.id,
    meta_mobile_number,
    coalesce(meta_first_name, 'Pending'),
    meta_middle_name,
    coalesce(meta_last_name, 'User')
  )
  on conflict (id) do update
  set
    mobile_number = excluded.mobile_number,
    first_name = excluded.first_name,
    middle_name = excluded.middle_name,
    last_name = excluded.last_name,
    updated_at = timezone('utc', now());

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.organizations (
  code,
  name,
  status,
  province,
  municipality,
  barangay,
  address
)
values (
  'SLPA-DEMO-001',
  'Demo SLPA Organization',
  'active',
  'Cebu',
  'Cebu City',
  'Demo Barangay',
  'Demo Purok 1'
)
on conflict (code) do nothing;

create or replace function public.seed_membership_for_user(
  target_user_id uuid,
  organization_code text default 'SLPA-DEMO-001',
  target_role_code text default 'slpa_admin'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_org_id uuid;
  target_role_id uuid;
begin
  select id into target_org_id
  from public.organizations
  where code = organization_code
  limit 1;

  if target_org_id is null then
    raise exception 'Organization with code % not found', organization_code;
  end if;

  select id into target_role_id
  from public.roles
  where code = target_role_code
  limit 1;

  if target_role_id is null then
    raise exception 'Role with code % not found', target_role_code;
  end if;

  insert into public.organization_memberships (
    organization_id,
    user_id,
    role_id,
    status
  )
  values (
    target_org_id,
    target_user_id,
    target_role_id,
    'active'
  )
  on conflict (organization_id, user_id, role_id) do nothing;
end;
$$;
