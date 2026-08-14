---
problem_type: feature_gap
component:
  - notification_inbox
  - notification_lifecycle
  - recurring_maintenance_jobs
symptoms:
  - read and unread notifications appeared in one undifferentiated list
  - users could not bulk-clear read notifications
  - read notifications accumulated without a retention policy
tags:
  - rails
  - notifications
  - authorization
  - data-retention
  - recurring-jobs
  - solid-queue
---

# Read notification lifecycle with user-scoped clearing and retention

## Problem

Marking a notification read did not meaningfully change its presentation or location, and read records accumulated indefinitely. Bulk and automatic cleanup had to preserve unread notifications and prevent one user from deleting another user's records.

## Solution

Load the authenticated user's notifications once in newest-first order, then partition the loaded collection into unread and read groups. Render read cards below a labeled divider with a faded gray treatment and expose “Clear All” only in that section.

Keep the destructive predicate in one database relation:

```ruby
current_user.notifications.read.delete_all
```

This simultaneously enforces recipient ownership and read state, even if a caller bypasses the UI. Use a collection `DELETE` route with normal authentication and CSRF protection.

Retain read notifications for 30 days from `read_at`, not `created_at`, then run a daily maintenance job using `in_batches.delete_all`. Old unread notifications remain untouched. A concurrent partial index on `read_at WHERE read_at IS NOT NULL` supports the global retention sweep; the existing `(recipient_id, read_at)` index continues to support per-user display and clearing.

## Regression strategy

- Verify unread cards render above the divider and read cards use faded styling without the unread accent.
- Verify “Clear All” is absent when there are no read notifications.
- Verify clearing deletes only the signed-in user's read rows and is harmless when repeated.
- Verify guests cannot clear notifications.
- Verify 31-day-old read rows are pruned while 29-day-old read rows and year-old unread rows survive.
- Parse recurring-job configuration to verify the class, maintenance queue, and daily schedule.
- Assert the partial retention index exists so cleanup does not silently regress to table scans.

## Related solutions

- [Account settings with notification channel and topic preferences](account-settings-with-notification-channel-and-topic-preferences.md)
- [Secure public job sharing and tokenized invitation auth handoff](../security-issues/secure-public-job-sharing-and-tokenized-invitation-auth-handoff.md)
