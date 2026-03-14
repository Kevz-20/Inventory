create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  status text not null default 'active' check (status in ('active', 'inactive', 'archived')),
  province text,
  municipality text,
  barangay text,
  address text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  created_at timestamptz not null default timezone('utc', now())
);

insert into public.roles (code, name)
values
  ('slpa_member', 'SLPA Member'),
  ('slpa_admin', 'SLPA Admin'),
  ('pdo_consultant', 'PDO Consultant'),
  ('system_admin', 'System Admin')
on conflict (code) do nothing;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  mobile_number text unique,
  first_name text not null,
  middle_name text,
  last_name text not null,
  status text not null default 'active' check (status in ('active', 'inactive', 'locked')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id),
  status text not null default 'active' check (status in ('active', 'inactive', 'invited')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (organization_id, user_id, role_id)
);

create table if not exists public.product_categories (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  created_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  unique (organization_id, name)
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  category_id uuid references public.product_categories(id),
  name text not null,
  purchase_price numeric(12, 2) not null default 0,
  selling_price numeric(12, 2) not null default 0,
  quantity integer not null default 0,
  image_path text,
  created_by_user_id uuid references public.profiles(id),
  updated_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  first_name text not null,
  middle_name text,
  last_name text not null,
  phone_number text,
  municipality text,
  barangay text,
  landmark text,
  credit_limit numeric(12, 2) not null default 1000,
  available_credit numeric(12, 2) not null default 1000,
  created_by_user_id uuid references public.profiles(id),
  updated_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  customer_id uuid references public.customers(id),
  sale_type text not null check (sale_type in ('cash', 'credit')),
  total_amount numeric(12, 2) not null default 0,
  created_by_user_id uuid references public.profiles(id),
  updated_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  product_id uuid not null references public.products(id),
  unit_price numeric(12, 2) not null,
  quantity integer not null,
  subtotal numeric(12, 2) not null
);

create table if not exists public.receivables (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  sale_id uuid not null references public.sales(id) on delete cascade,
  customer_id uuid not null references public.customers(id),
  original_amount numeric(12, 2) not null,
  remaining_amount numeric(12, 2) not null,
  status text not null default 'unpaid' check (status in ('unpaid', 'partial', 'paid')),
  due_date timestamptz,
  created_by_user_id uuid references public.profiles(id),
  updated_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.receivable_payments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  receivable_id uuid not null references public.receivables(id) on delete cascade,
  amount numeric(12, 2) not null,
  paid_at timestamptz not null default timezone('utc', now()),
  remarks text,
  created_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  created_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  unique (organization_id, name)
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  category_id uuid references public.expense_categories(id),
  amount numeric(12, 2) not null,
  description text,
  receipt_file_path text,
  created_by_user_id uuid references public.profiles(id),
  updated_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  actor_user_id uuid references public.profiles(id),
  entity_type text not null,
  entity_id uuid,
  action text not null check (action in ('create', 'update', 'delete', 'restore', 'sync', 'login')),
  old_values_json jsonb,
  new_values_json jsonb,
  device_id text,
  occurred_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_memberships_org on public.organization_memberships (organization_id);
create index if not exists idx_memberships_user on public.organization_memberships (user_id);
create index if not exists idx_products_org on public.products (organization_id);
create index if not exists idx_customers_org on public.customers (organization_id);
create index if not exists idx_sales_org on public.sales (organization_id);
create index if not exists idx_receivables_org on public.receivables (organization_id);
create index if not exists idx_expenses_org on public.expenses (organization_id);
create index if not exists idx_audit_logs_org on public.audit_logs (organization_id);

create trigger organizations_set_updated_at
before update on public.organizations
for each row execute function public.set_updated_at();

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger memberships_set_updated_at
before update on public.organization_memberships
for each row execute function public.set_updated_at();

create trigger product_categories_set_updated_at
before update on public.product_categories
for each row execute function public.set_updated_at();

create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();

create trigger customers_set_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

create trigger sales_set_updated_at
before update on public.sales
for each row execute function public.set_updated_at();

create trigger receivables_set_updated_at
before update on public.receivables
for each row execute function public.set_updated_at();

create trigger expense_categories_set_updated_at
before update on public.expense_categories
for each row execute function public.set_updated_at();

create trigger expenses_set_updated_at
before update on public.expenses
for each row execute function public.set_updated_at();
