create or replace function public.current_profile_id()
returns uuid
language sql
stable
as $$
  select auth.uid()
$$;

create or replace function public.is_system_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.organization_memberships om
    join public.roles r on r.id = om.role_id
    where om.user_id = public.current_profile_id()
      and om.status = 'active'
      and r.code = 'system_admin'
  );
$$;

create or replace function public.has_org_role(target_org uuid, allowed_roles text[])
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.organization_memberships om
    join public.roles r on r.id = om.role_id
    where om.organization_id = target_org
      and om.user_id = public.current_profile_id()
      and om.status = 'active'
      and r.code = any(allowed_roles)
  );
$$;

create or replace function public.can_access_org(target_org uuid)
returns boolean
language sql
stable
as $$
  select public.is_system_admin()
    or public.has_org_role(
      target_org,
      array['slpa_member', 'slpa_admin', 'pdo_consultant']
    );
$$;

create or replace function public.can_manage_org(target_org uuid)
returns boolean
language sql
stable
as $$
  select public.is_system_admin()
    or public.has_org_role(
      target_org,
      array['slpa_admin', 'pdo_consultant']
    );
$$;

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.product_categories enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.receivables enable row level security;
alter table public.receivable_payments enable row level security;
alter table public.expense_categories enable row level security;
alter table public.expenses enable row level security;
alter table public.audit_logs enable row level security;

create policy organizations_select
on public.organizations
for select
using (public.can_access_org(id));

create policy organizations_update
on public.organizations
for update
using (public.can_manage_org(id))
with check (public.can_manage_org(id));

create policy profiles_select_self_or_system_admin
on public.profiles
for select
using (
  id = public.current_profile_id()
  or public.is_system_admin()
);

create policy profiles_update_self_or_system_admin
on public.profiles
for update
using (
  id = public.current_profile_id()
  or public.is_system_admin()
)
with check (
  id = public.current_profile_id()
  or public.is_system_admin()
);

create policy memberships_select
on public.organization_memberships
for select
using (
  user_id = public.current_profile_id()
  or public.can_manage_org(organization_id)
);

create policy memberships_insert
on public.organization_memberships
for insert
with check (public.can_manage_org(organization_id));

create policy memberships_update
on public.organization_memberships
for update
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy product_categories_select
on public.product_categories
for select
using (public.can_access_org(organization_id));

create policy product_categories_modify
on public.product_categories
for all
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy products_select
on public.products
for select
using (public.can_access_org(organization_id));

create policy products_modify
on public.products
for all
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy customers_select
on public.customers
for select
using (public.can_access_org(organization_id));

create policy customers_modify
on public.customers
for all
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy sales_select
on public.sales
for select
using (public.can_access_org(organization_id));

create policy sales_insert
on public.sales
for insert
with check (public.can_access_org(organization_id));

create policy sales_update
on public.sales
for update
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy sale_items_select
on public.sale_items
for select
using (
  exists (
    select 1
    from public.sales s
    where s.id = sale_id
      and public.can_access_org(s.organization_id)
  )
);

create policy sale_items_modify
on public.sale_items
for all
using (
  exists (
    select 1
    from public.sales s
    where s.id = sale_id
      and public.can_manage_org(s.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.sales s
    where s.id = sale_id
      and public.can_manage_org(s.organization_id)
  )
);

create policy receivables_select
on public.receivables
for select
using (public.can_access_org(organization_id));

create policy receivables_modify
on public.receivables
for all
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy receivable_payments_select
on public.receivable_payments
for select
using (public.can_access_org(organization_id));

create policy receivable_payments_modify
on public.receivable_payments
for all
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy expense_categories_select
on public.expense_categories
for select
using (public.can_access_org(organization_id));

create policy expense_categories_modify
on public.expense_categories
for all
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy expenses_select
on public.expenses
for select
using (public.can_access_org(organization_id));

create policy expenses_insert
on public.expenses
for insert
with check (public.can_access_org(organization_id));

create policy expenses_update
on public.expenses
for update
using (public.can_manage_org(organization_id))
with check (public.can_manage_org(organization_id));

create policy audit_logs_select
on public.audit_logs
for select
using (
  organization_id is null and public.is_system_admin()
  or (organization_id is not null and public.can_manage_org(organization_id))
);

create policy audit_logs_insert
on public.audit_logs
for insert
with check (
  organization_id is null and public.is_system_admin()
  or (organization_id is not null and public.can_access_org(organization_id))
);
