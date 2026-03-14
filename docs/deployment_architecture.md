# Deployment Architecture

## Goal

Convert the current single-device Flutter app into an offline-first, server-backed system that supports:

- many SLPA groups
- many users per SLPA
- PDO or consultant monitoring
- accountability and transparency
- device-loss recovery
- centralized reporting and notifications

## Current State

The current app is a local-only Flutter application backed by SQLite through `lib/services/db_service.dart`.

Current limitations:

- no central server
- no organization or SLPA separation in the schema
- no real user roles or permissions
- no sync engine
- no centralized audit log
- no backup and recovery outside the device
- no admin or PDO monitoring portal

## Target System

Build an offline-first system with three parts:

1. Mobile app
   - Flutter app used by SLPA members
   - works offline for day-to-day operations
   - stores pending changes locally
   - syncs when internet is available

2. Backend API
   - central source of truth
   - authentication and authorization
   - organization isolation per SLPA
   - audit logs
   - notifications
   - reporting

3. Admin web portal
   - PDO and staff monitoring
   - user and group management
   - audit review
   - report export

## Recommended Architecture

### Client

- keep Flutter as the mobile client
- keep local SQLite for offline caching and queued writes
- add a sync layer instead of replacing the local database immediately

### Server

The backend must provide:

- auth and session management
- role-based access control
- multi-tenant SLPA isolation
- CRUD APIs for inventory, sales, expenses, utang, files, and reports
- audit logging for create, update, delete actions
- notification and email workflows
- backup and restore support

### Storage

- relational database for business records
- object storage for photos, receipts, and captured files

## Required Roles

- `slpa_member`: encode transactions and view assigned SLPA data
- `slpa_admin`: manage users within one SLPA
- `pdo_consultant`: view assigned SLPAs, reports, and audit history
- `system_admin`: full cross-organization administration

## Non-Negotiable Capabilities

### Multi-tenancy

Every business record must belong to:

- `organization_id`
- optionally `branch_id` if later needed

### Auditability

Every important record must track:

- who created it
- who last updated it
- when it was created
- when it was updated
- whether it was deleted

Sensitive actions should also generate an audit log event that stores:

- actor
- record type
- record id
- action type
- old values summary
- new values summary
- device id
- sync timestamp

### Offline Sync

The mobile app must keep:

- a local copy of assigned data
- a queue of offline changes
- sync metadata per record

Each syncable local record should eventually include fields like:

- `server_id`
- `local_uuid`
- `sync_status`
- `last_synced_at`
- `deleted_at`
- `updated_at`

### Recovery

If a phone is lost or damaged:

- the user logs in on a new device
- the app downloads the user and SLPA data from the server
- pending media and reports are restored from cloud storage where available

## Delivery Phases

### Phase 1: Foundation

- finalize requirements and role matrix
- define backend data model
- decide hosting and backend stack
- define API standards
- define audit and sync rules

### Phase 2: Backend Core

- implement authentication
- implement SLPA and user management
- implement permissions
- implement core modules:
  - products
  - inventory
  - sales
  - expenses
  - customers
  - utang
- implement audit log

### Phase 3: Mobile Sync Refactor

- introduce local sync metadata
- add API client layer
- queue local writes
- sync pull and push flows
- conflict handling

### Phase 4: Admin Portal

- PDO dashboard
- SLPA monitoring
- user management
- audit history screens
- report export

### Phase 5: Notifications and Recovery

- email notifications
- file uploads
- backup policies
- device migration process

## Immediate Work Items

These should be done before feature expansion:

1. define the tenant model for SLPA groups
2. define the user roles and visibility rules
3. map current SQLite tables to server entities
4. add sync metadata strategy
5. design the audit log format
6. choose backend stack and hosting

## Notes For The Existing Flutter App

The current app is still useful as the mobile client, but its schema assumes a single shared local database with weak separation between users. The first app-side refactor should not be "remove SQLite". It should be "make SQLite sync-capable and tenant-aware".
