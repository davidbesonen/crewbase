# Booking confirmation

Implemented September 27, 2026.

Employers now send a job offer instead of silently accepting an application or
assigning a worker. The offer records the role, work start/end, rate, currency,
pay unit, essential terms and optional response deadline. A worker accepts or
declines explicitly. Pending offers do not reserve capacity. The offer form
states this policy before sending.

Offers have pending, accepted, declined, withdrawn, expired and cancelled states.
The displayed status reflects elapsed response deadlines even before an action
persists the expired state. Changed terms create a new immutable offer and withdraw
the earlier pending offer. Existing accepted applications and crew assignments
remain legacy confirmed bookings.

Acceptance locks the job, worker profile, application and offer in that order.
Issuance uses the same ordering, rechecking authorization and current booking state
inside the transaction. A single-role job accepts one worker; crew positions use
their configured headcount. Acceptance rechecks calendar blockouts and confirmed
bookings across jobs. These conflict checks use calendar dates, conservatively
preventing simultaneous bookings on the same work day. They do not infer travel
buffers or guarantee external calendar completeness. No known conflict is not a
promise of availability. Connected feeds require a successful sync within 24 hours
and no sync error to count as availability evidence. Unknown availability does not
prevent a worker from explicitly confirming the offered dates.

The worker or company owner can cancel an upcoming confirmed booking with a reason.
The offer retains agreed terms, cancellation actor, time and reason; both parties
can see the history. Application review cannot silently undo confirmation.
Completed or ended work cannot be cancelled through this workflow. Positions with
confirmed offers must have their bookings cancelled before deletion. Replacements
need their own offer and cannot consume capacity until the old booking is cancelled.

Offers and response notifications are in-app. New offer email uses the preference-
aware delivery outbox. Upcoming reminders use confirmed offer dates; dashboard
bookings also display agreed dates rather than later edits to the posting.

This is booking confirmation, not payroll, legal contract signing, or payment
collection. Referral introductions and accountant/payment exports in the original
proposal remain separate work.

Verification includes workflow/authorization tests, expired and changed offers,
calendar and legacy booking conflicts, capacity rechecks, deleted positions,
cancellation history, invalid direct offer rollback, agreed dashboard dates, and a
real concurrent PostgreSQL acceptance test proving only one worker fills a role.

## Inbox and calendar export

The offers inbox separates offers needing the current worker's reply, offers
awaiting crew for companies they own, upcoming confirmed bookings, and history.
Search matches role, company, or crew member within the authorized collection.
Pending lists prioritize response deadlines; expired or ended offers and archived
jobs no longer appear as actionable. The dashboard highlights up to three offers
awaiting a reply and links to the complete list. Resolved applications and ended
work no longer crowd the current-applications card.

Either booking participant can download an accepted offer as a private `.ics`
calendar event. It uses the immutable agreed times in UTC and a stable event UID.
Pending and cancelled offers cannot be exported as confirmed bookings. The file
contains the role, company, location and authenticated booking URL, without pay,
private terms, email addresses or automatic attendee invitations. This is a
snapshot: importing it does not subscribe a calendar to future changes or remove
events automatically after cancellation. The download UI states that limitation.
