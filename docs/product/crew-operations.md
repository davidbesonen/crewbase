# Company crew operations

KnowShow combines public recruitment with private production planning. Company
owners access Crew Roster, Staffing Board, Templates and Venues from the company
workspace. A gig's Production Workspace holds operational details; Show Brief is
available only to owners and confirmed crew.

## Start staffing from the dashboard

Company owners choose **Staff a Gig**, **Post a Job**, or **Staff a Tour / Festival**
in Company Tools. Each resolves the company first; owners with multiple companies
choose the one they are staffing for.

Tours, festivals and multi-show events start as Projects. Name the Project,
add its shows/cities/dates (up to 50 in one save), then plan roles and crew. A
`ProjectShow` is a dated place, not a job. The Project has Shows & Cities,
Roles & Postings, and Crew By Show views, including a show/city filter.

A posting can cover the entire run (including future shows), selected shows,
or custom dates. `ProjectJobSchedule` synchronizes linked posting dates,
specific work dates and locations in the same transaction as a show edit or
posting save. Whole-run roles pick up newly added shows; selected roles retain
their selections. Linked shows cannot be removed until their staffing is moved.

Crew planning creates one private draft role per itinerary and optionally adds
a company roster member as tentative crew. Use separate plans when people work
different cities. Shared crew postings remain supported: all of their roles
and people share the selected shows. This is a staffing need within the Project,
not a nested festival or tour. Existing bookings and tentative plans remain
explicitly distinct.

Post a Job asks whether the role stands alone, adds a position to an existing
crew gig, or belongs to a Project. Existing-gig roles use its crew workspace
instead of making another unrelated posting. Single gigs still work without
Projects. New Projects use the multi-show workspace; legacy general Projects
keep their postings and can also use the show/crew tabs.

Offers snapshot work dates and the show itinerary. Changing a posting or
Project does not alter pending/accepted terms. Availability and calendar export
use actual agreed work dates, leaving gaps between shows unreserved. A changed
Project schedule is flagged on the offer; revised bookings require a new offer.

## Spreadsheet imports and account claims

- Upload `.xlsx` (first worksheet) or UTF-8 `.csv`, up to 5 MB and 500 people.
- Download the Excel template from Upload Spreadsheet. Recognized column aliases
  include Job Title, Role, Email Address, Phone Number, Years Worked With, Skills,
  Equipment and Notes. Unknown columns are ignored; duplicate mapped headers fail.
- First Name and Last Name are required. Each selected row needs a valid email
  and/or a phone number. Phone numbers should be stored as text in Excel to keep
  country codes and leading zeros.
- The upload creates a company-scoped, editable review, not crew members or user
  accounts. Correct fields or exclude rows before confirmation. Reviews expire
  after 24 hours; successful imports clear the temporary row data.
- Confirmation validates all selected rows and imports atomically. Company-level
  contact uniqueness catches existing and within-file duplicates. Re-submitting
  an already completed import does not add the crew again.
- Review uses compact person summaries, opens flagged rows and hidden field errors,
  and supports spreadsheet search, bulk selection and a persistent selection count.
  Search changes visibility, not selection. The browser submits a bounded JSON
  form part so 500 fully editable rows do not exceed Rack's parameter-count limit.
- A `CrewMember` is a private company record, initially without a login profile.
  Import does not invent email addresses, create passwords, publish profiles,
  send messages, or count these people as company administration seats.
- Owners create a signed, seven-day invitation link and share it with the named
  contact by email or phone. Creating another link revokes previous links.
  There is no dependency on an SMS provider or outgoing email configuration.
- The recipient signs up or signs in, then explicitly claims their record. If
  the roster has an email, the account email must match. For phone-only entries,
  the privately shared invitation link authorizes the claim. Links are bearer
  credentials and should be sent directly to the intended contact.
- Wrong-account invitations offer an explicit sign-out/sign-in action with a
  return path to the invitation. Expired, replaced and used links display recovery
  guidance without exposing a record error.
- Claim fills missing personal profile fields from role, contact, location,
  skills and equipment. It does not overwrite an existing personal profile or
  automatically publish/complete it. Company notes, years worked with the
  company and company-specific organization remain private.

## Staffing and private gigs

Invite-only published gigs are omitted from public job pages, discovery and
worker recommendations. Owners, invited applicants and hired crew can access
the relevant work. Existing public listings keep their previous visibility.
Application deadlines and closed/ended jobs still stop new invitations.

The four-week staffing board includes undated gigs, role/headcount needs,
confirmed crew, pending offers, declines, availability states and tentative
roster plans. A tentative hold is never a booking and does not consume confirmed
capacity. Claimed roster members are included in owner staffing candidates.
Existing offer acceptance remains responsible for confirming a booking and
checking availability/capacity.

Creating from the staffing board defaults to invite only. The form distinguishes
activating a private gig from publishing a public listing. Board filters retain
search/project context between date windows; empty multi-role gigs contribute no
invented open positions. Company workspace navigation uses a select on phones.

Availability continues using the existing conservative calendar-date checks.
The board does not claim that unknown availability is available and does not
introduce travel-time predictions or finer time-based conflict rules.

## Reuse, touring and production information

Duplicate a gig or save a company-owned template. A setup preserves requirements,
roles/headcounts, compensation suggestions, questions, descriptions and production
phases. A new start date shifts the schedule and specific work dates together.
New records are drafts. Applications, offers, confirmations, conversations,
reviews, private uploaded job documents and work credits are never copied.

Projects can create up to 50 dated tour stops from one gig/template. Stops may
select different saved venues. The batch is atomic and produces invite-only
drafts, ready for review before publishing or sending offers.

Production schedules distinguish load-in, show, load-out, travel and off days.
Saved schedule items collapse into summaries. Validation errors retain entered
details in an open editor. Venue options can refresh inside the show form while
preserving other unsaved show details after managing venues in a separate tab.
Times are optional and use the application's displayed time zone. Roles can be
associated with a schedule phase; new offers default to its dates/times. Editing
production information does not rewrite immutable accepted booking terms.

Saved venues contain reusable addresses, arrival/parking instructions and venue
contacts. Gigs can also specify a production contact and shared show notes.
Changing shared venue records updates all attached briefs. Roster notes are
never used as shared show notes.

Show Brief combines this information with confirmed crew's agreed offer times
and private document links. Tentative/unclaimed contacts and their private data
are excluded. Print / Save PDF uses the browser's print dialog. Printed copies
are snapshots; the current brief remains in KnowShow. Saving show information
notifies confirmed crew in the app without changing their agreed terms. Schedule
and shared venue changes also notify confirmed crew on affected upcoming gigs.
Selecting a venue synchronizes its city/state/address into the job location used
for discovery and recommendations.
