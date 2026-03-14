# Feature Decision Matrix

## Purpose

This document converts the current stakeholder suggestions into:

- a clearer feature list
- whether each feature needs a backend/server
- the recommended implementation priority
- the immediate next steps for the team

The current project direction is already an offline-first Flutter app with a
server-backed Supabase deployment for multi-SLPA use, monitoring, recovery,
and centralized reporting.

## Summary Decision

The requested future version should use:

- a Flutter mobile app for SLPA users
- local SQLite for offline work
- a backend/server for sync, recovery, monitoring, files, and notifications

This means the answer to "do we need a server?" is:

- yes, for the full requested scope
- no, only if the app remains single-device and local-only

## Feature Matrix

| Requested feature | Clarified interpretation | Needs server? | Priority | Notes |
| --- | --- | --- | --- | --- |
| Use SLPA name for account details | Each SLPA should be represented as an organization, not just an individual device account | Yes | High | Needs organization records and memberships |
| Security features | Add stronger login, auditability, permissions, and device-safe recovery | Yes | High | Can include PIN, biometrics, email login, audit log |
| Email notification | Notify relevant users when important records change | Yes | High | Requires backend events and email service |
| Offline version | App should continue working without internet and sync later | Yes | High | Offline mode itself is local, but reliable recovery and shared data need backend sync |
| View transaction history | Users can see prior sales and activity | No | Medium | Already partly present in app |
| Notify association or PDO when records are changed | Send alerts for edits or critical updates | Yes | High | Requires audit rules and notification triggers |
| Zoom in/out words | Adjustable text scaling for accessibility | No | Medium | Local UI preference |
| Change layout based on user preference | User-selectable layout, density, or dashboard arrangement | No | Low/Medium | Local preference unless shared across devices |
| Add inventory to dashboard | Show inventory summary or low-stock cards on dashboard | No | Medium | Mostly app-side UI/data composition |
| Lost or broken phone recovery | User can log in on a new device and restore data | Yes | High | Strong reason backend is required |
| Where captured files are stored | Define storage for photos, receipts, and attachments | Yes | High | Use cloud object storage plus local cache |
| Generate reports in Excel or Word aside from PDF | Export structured reports in more formats | Mixed | Medium | Export can be local; centralized and cross-org reporting needs backend |
| Minimum specs needed | Define device and operating requirements | No | Medium | Product and deployment decision |
| App updates after install | Support normal app update flow without reinstalling from scratch | No | Medium | Standard mobile release process |
| PDO/consultant or mother account with overall access | Monitoring role with visibility over assigned SLPAs | Yes | High | Requires role-based backend access |

## Decisions To Confirm Now

These should be answered before implementation starts:

1. Will login remain mobile-number plus PIN, or move to email plus password, or support both?
2. Should PDO accounts have read-only access, or can they also edit and approve records?
3. Which changes should trigger email alerts?
4. Which files will be uploaded: receipts, product photos, signatures, reports, or all of them?
5. Which exports are required in Phase 1: PDF only, or PDF plus Excel?
6. Is Word export really required, or will Excel and PDF be enough?
7. Should UI preferences sync across devices, or stay local on each device?
8. What happens to offline records if a device is lost before syncing?

## Recommended Scope By Phase

### Phase 1: Requirements Lock

Goal:
- remove ambiguity from the requested features
- freeze the first delivery scope

Deliverables:
- approved feature list
- approved role matrix
- approved notification triggers
- approved recovery rules
- approved report/export list

### Phase 2: Backend Foundation

Goal:
- make the system ready for multi-SLPA use and recovery

Build:
- organizations for SLPAs
- users and memberships
- roles:
  - `slpa_member`
  - `slpa_admin`
  - `pdo_consultant`
  - `system_admin`
- row-level access rules
- audit logs
- file storage metadata
- notification tables and workflows

### Phase 3: Mobile Sync Refactor

Goal:
- keep the app usable offline while syncing to the backend

Build:
- local sync metadata on SQLite tables
- push local changes when online
- pull remote changes from server
- device recovery flow
- file upload sync

### Phase 4: Monitoring And Reports

Goal:
- enable PDO/staff oversight and organization-level reporting

Build:
- PDO monitoring screens
- organization summaries
- transaction history review
- audit history review
- export options for approved report formats

### Phase 5: UX Enhancements

Goal:
- complete local usability improvements

Build:
- text zoom controls
- layout preferences
- dashboard inventory cards
- update guidance and minimum specs documentation

## Immediate Next Steps

These are the next actions the team can do now.

1. Approve the architecture decision:
   - offline-first mobile app
   - backend/server required for full scope

2. Finalize the role matrix:
   - what SLPA users can do
   - what SLPA admins can do
   - what PDO/consultants can view or manage

3. Finalize the account model:
   - SLPA as organization
   - user account type
   - authentication method

4. Finalize the notification rules:
   - which edits trigger email
   - who receives alerts
   - whether alerts are immediate or batched

5. Finalize the recovery policy:
   - how a lost phone is replaced
   - what data is restored
   - what happens to unsynced records

6. Finalize the file-storage policy:
   - what files are captured
   - where they are stored
   - retention and access rules

7. Finalize the report list:
   - which reports are required
   - which formats are required
   - whether export is per user, per SLPA, or cross-SLPA

8. Start backend completion work already identified in the repo:
   - complete remaining backend tables
   - complete RLS and membership bootstrap
   - connect Flutter auth and sync flows to Supabase

## First Technical Work Order

If the team wants the implementation sequence immediately after approval, use
this order:

1. deploy and verify current Supabase migrations
2. seed one SLPA organization and one admin user
3. finish auth and profile bootstrap
4. define and implement PDO monitoring access
5. add notification and file metadata tables
6. add missing sync metadata in the Flutter local database
7. connect key modules first:
   - products
   - inventory
   - sales
   - expenses
   - transaction history
8. implement device recovery test flow
9. add export enhancements
10. add zoom and layout preferences

## Recommendation

Do not start with cosmetic items first.

Start with:

- roles and permissions
- backend data ownership
- sync and recovery
- monitoring access
- notifications

After those are stable, add:

- exports
- dashboard inventory improvements
- text zoom
- layout preferences
