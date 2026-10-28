# Crew roster import and claim audit

Audited locally on October 28, 2026 using real `.xlsx` workbooks with dummy
contacts, integration tests, and desktop/mobile browser journeys. Addresses use
`example.com`; phone numbers use reserved dummy ranges. No real crew were
contacted. Browser tests use the isolated test database.

## What the product does

1. A company owner or employee uploads the first worksheet of an Excel file or
   UTF-8 CSV. The upload creates a temporary, private review, not user accounts.
2. Every selected person needs First Name, Last Name, and at least one valid
   Email or Phone. Owners can correct fields or exclude people before import.
3. Confirmation adds private `CrewMember` records atomically. An error prevents
   the whole selected batch from saving. Duplicate normalized contacts within a
   company require correction. A successful review cannot import twice.
4. Import sends **no email or text** and creates no login or public profile.
   Existing accounts are not automatically attached by matching their email.
5. An owner opens a crew record and chooses **Create Invitation Link**, then
   shares the link directly. Employees can upload but cannot manage invitations.
6. The recipient creates an account or signs in, then explicitly chooses
   **Claim And Complete My Profile**. Email roster entries require the same login
   email. Phone-only contacts may choose their account email. Possession of the
   signed link authorizes a phone-only claim; there is no SMS verification.
7. Claim attaches the account's user profile and fills missing role/headline,
   contact, location, skills, and equipment. It preserves existing profile data.
   The user must finish configuration; a new profile is not marked complete.
   Roster notes, years worked with the company, and internal organization are not
   copied. Claiming does not make the person a company employee or accept a gig.

Links expire seven days after creation. Viewing/copying does not renew that
deadline. Replacing a link, changing its email/phone, claiming the record,
removing the record, or restricting its company makes the old link unavailable.
Expired, replaced and used links show recovery instructions. Existing pending
links created before the stored-expiry migration need a fresh owner-generated
link. Claimed profiles are unaffected by that migration.

## Coverage

| Area | Verified cases |
| --- | --- |
| Real Excel files | Five valid crew, seven rows requiring review, first worksheet only, multiline equipment/skills, accented names/cities, fractional years, numeric phone cells |
| File boundaries | Empty upload, non-file input, wrong extension, corrupt ZIP/XLSX, malformed CSV and UTF-8, damaged workbook/relationship/sheet/shared-string XML |
| Resource limits | 5 MB upload cap, 25 MB expanded ZIP cap, 1,000 archive entries, 30 Excel columns, actual Excel files with 500 accepted and 501 rejected rows |
| Headers | Missing names/contact columns, duplicate mapped aliases, BOM, alternate header labels, ignored unknown columns |
| Contact validation | Missing contact, invalid email/phone, letters/extensions, normalization, duplicate contacts within spreadsheet/company, same contact in different companies |
| Review | Inline errors, corrected values, exclusions, all rows excluded, expired review, malformed JSON/form shapes, 500-row JSON submission, atomic failure, repeated import |
| Permissions | Owner and employee upload, outsider/roster-only denial, company isolation, revoked membership, owner-only invitations |
| Claims | Email-only signup, phone-only signup on mobile, existing account, duplicate signup, wrong password, wrong account, return after authentication, used/expired/replaced/changed/deleted links |
| Privacy | No account/profile/email on import, no automatic link to existing account, escaped markup, company notes stay private, existing profile preserved, no company membership granted |
| Concurrency | Import locks/idempotency; claim checks the current token and deadline again after locking the roster record |

The app's Excel template and the two reusable audit workbooks are independently
read by the production importer. Additional limit/error workbooks are generated
inside parser tests. Complete browser journeys exercise upload, review, save,
registration/login, claim, and profile configuration.

Final verification: `bin/rails test` passed 962 tests and 7,564 assertions;
the roster audit and crew operations browser suites passed nine tests and 136
assertions. RuboCop inspected 782 files with no offenses. The architecture
boundary tests are included in the full Rails suite.

## Fixed during this audit

- Malformed ordinary review parameters could cause a server error.
- Passing a string instead of an uploaded file could cause a server error.
- Damaged workbook metadata could expose a Roo exception or misleading missing
  header error. XML is now checked strictly before workbook parsing.
- Viewing an invitation could mint a token with another seven days. A stored
  deadline now prevents renewal, and claim validation is repeated under lock.
- Phone letters/extensions could be silently folded into a different number.
  Such entries now require correction.
- Error summaries used row numbers that disagreed with the spreadsheet and
  could grow to hundreds of messages. They now identify people by name, show
  three summaries at most, and retain all inline field errors.
- The expanded-workbook cap now checks actual bytes while reading, including
  archives that understate their size. Empty unrelated archive entries remain
  supported.
- Upload, crew record and claim copy now distinguish private roster contacts
  from login profiles and explain that creating a link sends no message.

## Remaining product choices

Automatic invitation delivery is not implemented. The current manual-link flow
works without email/SMS configuration. If email delivery is added, a useful next
step is an explicit **Email Selected Invitations** action after successful
review, with delivery status and resend controls. Upload itself should continue
to avoid contacting people before the owner has reviewed their details.

Phone-only links are bearer credentials, not proof of phone ownership. A future
verified-phone flow would need an SMS provider and a code verification step.
The current screens explain direct private sharing and the requirement to add
an email address for the KnowShow login.

No finite suite establishes that every possible workbook or failure mode is
handled. The listed cases are the verified coverage and now have regression
tests. Production email deliverability was not tested because this flow sends
no invitations automatically.
