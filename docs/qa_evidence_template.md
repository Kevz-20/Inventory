# QA Evidence Template

Use this template while running the real Supabase/device QA pass.

Fill one section per scenario from:

- `docs/supabase_deployment_qa_checklist.md`

---

## Test Session

- Date:
- Tester:
- Device / Emulator:
- App build / branch:
- Supabase project:
- Test organization:
- Test user:

---

## Scenario Record

### Scenario Name

- Example: `Offline Queue -> Product Sync`

### Purpose

- What this scenario is validating

### Preconditions

- signed-in user:
- selected organization:
- internet state:
- backend data state:

### Steps Performed

1. 
2. 
3. 

### Expected Result

- 

### Actual Result

- 

### Outcome

- `Pass`
- `Fail`
- `Blocked`

### Evidence

- Screenshot path or filename:
- Screen observed:
- SQL query used:
- Backend row IDs:
- Local record IDs / `local_uuid` / `server_id`:

### Notes

- duplicates observed:
- conflict observed:
- retry behavior:
- org isolation notes:
- audit log notes:

---

## Recommended Scenario List

Copy these into separate records as needed:

- Product Sync
- Customer Sync
- Offline Queue
- Cash Sale Sync
- Credit Sale Sync
- Customer Payment Sync
- Retry Flow
- Conflict Flow
- Organization Safety
- Admin Monitoring
- Organization Detail
- Admin Reports

---

## Final QA Summary

- Total scenarios executed:
- Passed:
- Failed:
- Blocked:

### Critical Findings

- 

### Follow-up Fixes Needed

- 

### Release Recommendation

- `Ready for wider testing`
- `Needs fixes before wider testing`
- `Blocked from deployment`
