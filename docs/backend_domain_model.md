# Backend Domain Model

## Purpose

This document maps the current local SQLite design to a deployable server-backed model for multi-SLPA use.

## Current App Modules

From `lib/services/db_service.dart`, the current app already covers these domains:

- accounts
- customers
- products and product categories
- stock in
- sales and sale items
- sales credit and customer payments
- expenses and expense categories
- capital management and bank transactions
- payables and payable payments
- fixed assets
- owner installments
- notifications

## Core Server Entities

### Organizations

- `organizations`
  - `id`
  - `code`
  - `name`
  - `status`
  - `address`
  - `province`
  - `municipality`
  - `barangay`
  - `created_at`
  - `updated_at`

Each SLPA group should be an organization.

### Users

- `users`
  - `id`
  - `email`
  - `mobile_number`
  - `password_hash`
  - `first_name`
  - `middle_name`
  - `last_name`
  - `status`
  - `last_login_at`
  - `created_at`
  - `updated_at`

### Memberships

- `organization_memberships`
  - `id`
  - `organization_id`
  - `user_id`
  - `role_id`
  - `status`
  - `created_at`
  - `updated_at`

This separates user identity from SLPA membership.

### Roles

- `roles`
  - `id`
  - `code`
  - `name`

Initial role codes:

- `slpa_member`
- `slpa_admin`
- `pdo_consultant`
- `system_admin`

## Business Entities

All business tables below should include at least:

- `organization_id`
- `created_by_user_id`
- `updated_by_user_id`
- `created_at`
- `updated_at`
- `deleted_at`

### Products

Maps from current local tables:

- `product`
- `product_category`
- `stock_in`

Proposed server tables:

- `product_categories`
- `products`
- `inventory_movements`

`inventory_movements` should replace isolated stock events with typed movement records such as:

- `stock_in`
- `sale`
- `adjustment`
- `return`

### Customers

Maps from:

- `customer`

Proposed:

- `customers`

### Sales

Maps from:

- `sales`
- `sale_item`
- `sales_cash`
- `sales_credit`
- `customer_payment`

Proposed:

- `sales`
- `sale_items`
- `receivables`
- `receivable_payments`

Reason:

The current schema splits cash and credit into separate reporting tables. For a server-backed design, one `sales` aggregate with related payment and receivable records is easier to audit and sync.

### Expenses

Maps from:

- `expenses`
- `expense_category`

Proposed:

- `expense_categories`
- `expenses`

### Capital And Cash

Maps from:

- `capital_management`
- `capital_transaction`
- `bank_transaction`
- `balance_assets`

Proposed:

- `capital_entries`
- `cash_accounts`
- `cash_movements`
- `balance_snapshots`

### Payables

Maps from:

- `payable`
- `payable_payment`
- `owner_installments`

Proposed:

- `payables`
- `payable_payments`
- `owner_financing_records`

### Fixed Assets

Maps from:

- `fixed_asset`

Proposed:

- `fixed_assets`

### Files

Current app stores file paths locally in fields such as receipt and image paths. For deployment, files should move to a dedicated table:

- `files`
  - `id`
  - `organization_id`
  - `storage_key`
  - `original_name`
  - `mime_type`
  - `size_bytes`
  - `uploaded_by_user_id`
  - `created_at`

Business tables should reference `file_id` instead of raw local paths when synced.

## Audit Model

Add a dedicated audit log table:

- `audit_logs`
  - `id`
  - `organization_id`
  - `actor_user_id`
  - `entity_type`
  - `entity_id`
  - `action`
  - `old_values_json`
  - `new_values_json`
  - `device_id`
  - `occurred_at`

Actions:

- `create`
- `update`
- `delete`
- `restore`
- `sync`
- `login`

## Notification Model

Suggested tables:

- `notifications`
- `notification_recipients`
- `notification_templates`

Triggers can be raised for:

- edited critical records
- overdue receivables
- overdue payables
- low inventory
- user/account changes

## Sync Model

The current SQLite tables do not support sync metadata yet. For offline-first deployment, each local syncable table should eventually include:

- `local_uuid`
- `server_id`
- `sync_status`
- `last_synced_at`
- `deleted_at`

Suggested `sync_status` values:

- `local_only`
- `pending_upload`
- `synced`
- `conflict`
- `sync_error`

## API Surface

Minimum API groups:

- `/auth`
- `/organizations`
- `/users`
- `/memberships`
- `/products`
- `/inventory`
- `/customers`
- `/sales`
- `/receivables`
- `/expenses`
- `/payables`
- `/reports`
- `/files`
- `/notifications`
- `/audit-logs`
- `/sync`

## First Refactor Targets In The App

The first mobile refactor should focus on these current local assumptions:

1. `account` is currently the main identity model.
   - this must become server-backed `users` plus organization membership.

2. Most transaction tables are missing `organization_id`.
   - tenant ownership must be explicit.

3. Several tables store creator names only.
   - switch to `created_by_user_id` while still allowing display names.

4. Files are stored as local paths.
   - add an abstraction for local file path vs synced cloud file id.

5. Reporting reads directly from local tables.
   - reporting must support both local cached data and synced server data.

## Build Order Recommendation

1. finalize server schema
2. implement auth, organizations, and memberships
3. migrate products, customers, and sales first
4. add audit logging
5. add offline sync metadata to local tables
6. add file sync
7. add PDO monitoring portal
