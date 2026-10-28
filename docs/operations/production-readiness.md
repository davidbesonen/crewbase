# Crewbase operations and launch verification

The app includes an administrator-only **Operations** page at `/admin/operations`.
It reports email delivery states, interrupted sends, Solid Queue worker/scheduler
heartbeats, failed queue jobs, and unprocessed Stripe events. It exposes no mail
bodies, recipient addresses, credentials, or webhook payloads. `bin/rails
operations:report` prints the same operational counts for an operator.

These checks do not certify production. This implementation was verified against
local test databases and the test mail transport. No production emails, payment
requests, or backup restores were performed.

## Email and scheduled work

Configure `APP_HOST` (hostname only), `MAILER_FROM` (verified sender),
`SMTP_ADDRESS`, `SMTP_PORT` (default 587), `SMTP_USERNAME`, and `SMTP_PASSWORD` in
the deployment's secret store. Production uses authenticated SMTP with STARTTLS,
10-second connection/read timeouts, and raised delivery errors. Configure SPF,
DKIM, and DMARC with the chosen provider. Verify an authorized test recipient gets
a real message, follows an HTTPS link to this deployment, and can disable email
from Settings before enabling scheduled notifications for real accounts.

Run `bin/jobs` alongside the web process. A web `/up` response only confirms that
Rails boots; it does not prove a worker, scheduler, SMTP, or Stripe is healthy.
Operations should show recent Worker and Scheduler heartbeats. Alert on missing
heartbeats for five minutes, failed executions, pending deliveries older than one
hour, and unprocessed Stripe events older than 15 minutes.

Production recurring work (in the deployment's configured scheduler timezone):

- Daily at 9am: at most one email per user with up to five newly published matching
  jobs from the last 24 hours.
- Monday at 10am: at most one weekly digest per user with up to five current matches.
- Hourly: reminders for accepted offers or legacy accepted applications starting
  in the next 24 hours. Pending, declined, and cancelled offers are excluded.

Matching uses the same recommender as the app, including feedback and availability
rules. Account email and category preferences are checked when scheduling and
again immediately before delivery. Matching and booking validity are checked again
at send time. A daily alert and weekly digest are separate subscriptions; users
can disable either. Emails include a Settings link. SMS is explicitly unavailable;
there is no SMS sender or active SMS subscription setting.

The schedule is intentionally production-only to avoid emailing local seed users.
Tests use Action Mailer's test transport. Do not run delivery jobs against an
ordinary development database with live SMTP settings.

### Delivery recovery

`NotificationDelivery` is an outbox with a database-unique deduplication key.
Multiple queued jobs cannot claim the same pending delivery twice. States:

- `pending`: queued or awaiting enqueue recovery.
- `sending`: claimed before SMTP. A process interruption leaves it here.
- `sent`: transport accepted the message; inbox placement is not guaranteed.
- `skipped`: preferences changed or no valid matching job/booking remains.
- `failed`: an exception occurred after the delivery was claimed. Only the error
  class is retained; provider responses can contain personal data.

A scheduler/queue crash can leave a pending record without a queued job. After
repair, an operator can enqueue its existing ID with
`DeliverNotificationEmailJob.perform_later(id)`. The claim prevents duplicate sends.
For `failed` or `sending`, first inspect provider logs using recipient/time in an
access-controlled console. SMTP can accept a message before the client loses its
connection, so never blindly retry these states or bulk reset them. After verifying
that the provider did **not** accept it, an operator may reset that exact delivery
to `pending` and enqueue its ID. Preserve the investigation in the incident log.

## Billing recovery

Configure Stripe keys, price IDs, and the signed `/stripe/webhooks` endpoint. Test
with Stripe test mode before live mode. Confirm a successful checkout activates the
correct account, a failed renewal moves it to `past_due`, updating payment details
through the billing portal recovers it after `invoice.paid`, and cancellation does
not accidentally preserve paid entitlements. Existing `ProcessStripeEvent` tests
cover event deduplication and subscription transitions locally.

The application stores each signed event before processing. Operations counts rows
without `processed_at`. Fix the cause (missing price mapping, customer mismatch,
provider configuration), then use Stripe's authenticated event-redelivery UI or
replay **only that recorded event** through `ProcessStripeEvent` in an operator
console. Successfully processed events are idempotent. Do not alter subscription
rows or manually mark an unprocessed event complete to silence the warning. Never
replay an unverified payload copied from a support message.

## Backups and restoration

Production uses hosted S3-compatible storage when `S3_BUCKET` is configured and
falls back to local Active Storage otherwise. The Render demo uses hosted storage.
Back up the configured object bucket (including Shrine uploads), or the persistent
`storage/` volume for a local-storage deployment, as well as the primary database;
database-only backups lose uploaded files.
Also protect the queue database and encrypted credentials/deployment secret store.
Use encrypted, access-controlled backups with retention and off-site copies.

Before launch, and after changing storage or database infrastructure:

1. Record the backup timestamp, retention, owner, expected recovery point and time.
2. Restore a recent backup into an isolated database and storage volume. Never
   point a restore drill at the live database, SMTP provider, or live Stripe keys.
3. Boot the restored app with email delivery disabled and no workers/scheduler.
4. Verify users, company ownership, accepted offers, applications, subscriptions,
   and a sample of authorized uploaded documents. Check attachment checksums.
5. Inspect restored notification outbox and queue work before enabling any worker;
   reconcile already-sent messages and already-processed Stripe events to avoid
   replaying external effects.
6. Document actual restore time, data loss window, and any failed checks. Keep the
   dated drill result with deployment records. The Operations page deliberately
   cannot mark this complete based on an environment flag alone.

## Safe local verification

Run the notification, offer, subscription/webhook, operations, and authorization
regressions with `RAILS_ENV=test` and the test mail adapter. Run `bin/rails test` and
`bin/rubocop` before deployment. View `/admin/operations` as an administrator and
verify a normal account cannot access it. No production secrets or live provider
requests are needed for these checks.
