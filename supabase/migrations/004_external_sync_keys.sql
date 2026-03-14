alter table public.products
add column if not exists external_local_uuid text;

alter table public.customers
add column if not exists external_local_uuid text;

alter table public.sales
add column if not exists external_local_uuid text;

alter table public.sale_items
add column if not exists external_local_uuid text;

alter table public.receivables
add column if not exists external_local_uuid text;

alter table public.receivable_payments
add column if not exists external_local_uuid text;

create unique index if not exists ux_products_org_external_local_uuid
on public.products (organization_id, external_local_uuid)
where external_local_uuid is not null;

create unique index if not exists ux_customers_org_external_local_uuid
on public.customers (organization_id, external_local_uuid)
where external_local_uuid is not null;

create unique index if not exists ux_sales_org_external_local_uuid
on public.sales (organization_id, external_local_uuid)
where external_local_uuid is not null;

create unique index if not exists ux_sale_items_external_local_uuid
on public.sale_items (external_local_uuid)
where external_local_uuid is not null;

create unique index if not exists ux_receivables_org_external_local_uuid
on public.receivables (organization_id, external_local_uuid)
where external_local_uuid is not null;

create unique index if not exists ux_receivable_payments_org_external_local_uuid
on public.receivable_payments (organization_id, external_local_uuid)
where external_local_uuid is not null;

create index if not exists idx_products_external_local_uuid
on public.products (external_local_uuid);

create index if not exists idx_customers_external_local_uuid
on public.customers (external_local_uuid);

create index if not exists idx_sales_external_local_uuid
on public.sales (external_local_uuid);

create index if not exists idx_sale_items_external_local_uuid
on public.sale_items (external_local_uuid);

create index if not exists idx_receivables_external_local_uuid
on public.receivables (external_local_uuid);

create index if not exists idx_receivable_payments_external_local_uuid
on public.receivable_payments (external_local_uuid);
