# Reporting, blocking, and moderation

Members can report published profiles, public job postings, companies they can access, visible work credits, reviews they can access, and conversations they participate in. Reports accept a reason and requested correction, preserve a subject label, and are visible only to their reporter and administrators. Reports do not notify the reported person. User-supplied target types are resolved through an explicit allowlist and visibility checks.

The profile's Trust & support section opens reporting and block controls. Credit correction links open a credit dispute. Reports & blocked people also lists reviews of the member and their owned companies, so people can dispute reviews even when those reviews are not shown on their own profile.

Blocking prevents new connection requests, accepted connections, network job shares, invitations, and new offers between the two users, including invitations addressed to an existing account's email. It ends an existing network connection; unblocking does not restore one. It does not hide public information, delete employment records, cancel applications/bookings, or remove existing contextual job conversations. Those conversations remain available for work coordination and reporting; this exception is explained before blocking and on the support page. A block is not a universal communication ban.

Administrators open the Reports queue from admin navigation. Each decision records the administrator, previous status, new status, timestamp, and mandatory findings/actions. A case may be reopened; history is retained. Internal notes are not exposed to the reporter. Marking a case resolved or dismissed does not automatically delete or change content. Administrators must investigate and document any correction or follow-up completed through the appropriate authorized workflow. Never treat an unverified report as proof of misconduct.

Self-reported experience is labeled as such. A verified Crewbase credit represents the app's recorded work relationship; it is not identity verification, a professional certification, or a blanket endorsement of skill. Report links allow corrections to be requested without editing verification evidence.

Unfinished personal profiles are not published in the directory or accessible through another person's direct profile link. The owner can preview their own unfinished profile.

## Validation

`test/integration/trust_and_safety_test.rb` covers private reports, target visibility, forged parameters, admin authorization and decision audit history, credit/review disputes, both directions of blocking, email-invitation bypass prevention, existing conversation access, and unfinished profile privacy. Existing network, conversation, credit, and architecture tests are also run.

## Site administration

Both `admin` and `app_owner` accounts can open `/admin`, or choose **Site admin**
from their workspace account menu. **Workspace** returns to the regular product.
Only app owners can grant or revoke another member's `admin` role. The interface
cannot change app-owner roles. Staff accounts and the acting administrator are
protected from suspension; an owner must revoke a staff role before suspension.

User, company, and job indexes link to searchable management records. Each detail
page shows linked records, relevant reports, subscription history where applicable,
and its latest 20 administrative changes, with a link to the full filtered audit
log. Correctable fields deliberately exclude passwords, account email, billing
identifiers, subscription state, and ownership.

For an investigation, open **Reports**, review the evidence, and use **Manage**
to open the relevant record. Choose the action and enter an internal reason.
A user suspension prevents password/OAuth authentication, revokes access on the
next HTTP request, disconnects current Action Cable connections, hides profiles
from discovery and recommendations, and blocks new invitations (even by email) and new offers.
A company/job hold removes public visibility and stops new applications and offers; company
holds also apply to all of that company's jobs. Holds cannot be cleared by normal
profile/company/job editing. Owners and existing hired crew retain access to work
records. Holds do not delete records, cancel bookings, or cancel subscriptions.
Restore the record after review, then record the outcome on the report. Resolving
a report alone does not remove a hold or change its subject.

Every management change and report decision records the actor, time, subject,
reason, and allowed before/after values in `/admin/audit_events`. Audit records
are append-only through the application, and writes occur in the same transaction
as the change. This is an operational history, not a cryptographically tamper-proof
ledger. Existing decisions remain in each report's history; only new decisions
appear in the shared audit log.

**Billing** provides searchable company subscription state, period-end cancellation
flags, and Stripe reference IDs. Personal subscription history is available on the
user detail page. Use the payment provider for refunds and cancellations. The
**Operations** page remains the source for delivery, queue, and webhook health;
counts alone do not verify production readiness.

The admin workflow is covered by `test/integration/admin_management_test.rb`,
`test/components/admin/record_management_component_test.rb`, and
`test/system/admin_management_test.rb`, including desktop and mobile rendering.
