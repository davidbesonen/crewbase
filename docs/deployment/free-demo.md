# Free Crewbase demo

Render runs one Ruby web service on its Free plan. Neon supplies PostgreSQL and
private S3-compatible object storage, both in AWS Ohio. No paid worker or disk is
required. Render can sleep after inactivity, so the first request can take about
a minute; scheduled jobs only run while the service is awake.

`render.yaml` describes the service. Run `bin/render-build` to install dependencies
and compile assets; `bin/render-start` prepares the four databases, initializes
sample records once, then starts Puma. Set these encrypted environment variables
in Render (never commit their values):

- `DATABASE_URL`: Neon `neondb` connection string.
- `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, `CABLE_DATABASE_URL`: the same Neon
  endpoint and role, using `crewbase_cache`, `crewbase_queue`, `crewbase_cable`.
- `SECRET_KEY_BASE`: a generated random Rails session secret.
- `DEMO_OWNER_PASSWORD`: a generated password with at least 16 characters.
- `S3_ENDPOINT`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`: credentials for this
  demo branch's object storage. `S3_BUCKET=crewbase-demo`, `S3_REGION=us-east-2`.

The Blueprint sets `CREWBASE_DEMO=true`, a single Puma process, and Solid Queue's
threaded supervisor mode to fit the free instance. Keep database TLS enabled.
Uploads stay private and are served using signed URLs. The app uses its existing
authorization rules for attachments.

The demo contains fictional crew, a company on the Team plan, and three sample
openings. Visitors can create their own accounts. The owner account is
`owner@crewbase-demo.example`; retrieve its password from the Render environment.
Repeated deploys preserve accounts, edits, passwords, and uploads. Changing the
seed password environment variable does not reset an existing account.

Payments, Google login, and outbound email are disabled in demo mode. Email
password-reset links are therefore unavailable. In-app messages and notifications
continue to work. No local database, local uploads, Rails master key, Stripe key,
or production credentials should be copied into this deployment.

Do not run `db:seed` on the hosted database: the legacy development seed resets
records. Automatic production seeding is disabled; `demo:seed` is the opt-in,
non-destructive bootstrap. Keep the hosting plans on Free to enforce the $0 demo
budget; hitting free allowances may suspend service until they reset.
