# Offers, referrals, and company reporting

Status: booking confirmation implemented; referrals and reporting remain proposed.
Updated: September 27, 2026.

See [Booking confirmation](booking-confirmation.md) for the current offer workflow,
availability policy, cancellation behavior and verification. The design notes below
retain the original proposal for referrals and reporting.

## Scope of the networking release

My Network contains private accepted connections, incoming/outgoing requests, and
people with visible verified credits on the same completed gigs with overlapping
dates. Connections are mutual; shared history never implies an endorsement.
Published, open jobs can be shared privately with an accepted connection. Sharing
creates an in-app notification, not an application, employer referral, or booking.
Company shortlists remain separate. There is no public network directory, social
feed, connection count ranking, or unrestricted messaging between strangers.

Completed gig history uses existing verified credits, respects each peer's credit
visibility settings, and does not expose company-internal projects. Historical
work without a completed Crewbase gig and verified credits is not inferred.

## Lightweight offers and referrals

Recommendation: keep booking confirmation in Crewbase. Negotiations can happen
in the existing job conversation or externally. Record the resulting agreed
terms and explicit response without building negotiation rounds, payroll, or
contract signing into the initial offer feature.

Pre-offer behavior: AcceptJobApplication marked an application accepted and, for a
multi-position gig, creates a crew assignment. It also opens a job conversation.
DashboardWorkSchedule treats accepted applications or assignments as bookings.
Do not silently reinterpret historical accepted applications when adding offers.

Proposed workflow:

1. Owner selects “Offer job,” chooses the role, confirms work dates, currency,
   agreed rate and pay unit, any essential terms, and an optional expiry.
2. A JobOffer captures an immutable snapshot of those terms. The application
   displays “Offer pending”; the crew calendar does not call it a confirmed booking.
3. The recipient can accept or decline and use a job-scoped conversation for questions.
4. Acceptance atomically checks availability/capacity and confirms the booking.
   Existing accepted applications should be treated as legacy confirmed bookings.
5. Declining can offer “Suggest a connection.” This is optional and never prevents
   a decline. Ask the selected connection whether they are interested before
   introducing them to the owner. Keep the referrer's decline reason private.
6. The owner reviews the interested referral and sends a separate offer. A
   referral never transfers a booking or promises the person's availability.

Use explicit pending, accepted, declined, withdrawn, and expired offer states.
A pending offer may reserve a position until a stated expiry; that policy must be
visible to owners and consistent across assignment, capacity, and availability
queries. Reissuing changed terms needs a new offer version and a fresh response.
Concurrent acceptance, owner withdrawal, deleted positions, expired offers, and
repeated requests must have transactional tests. Handle owner-created direct
assignments consistently so that they cannot bypass the confirmation requirement.

The first release should describe this as booking confirmation. Legal terms and
e-signature handling require a separate product decision. Measure offer response
and confirmation rates, expired offers, and referrals leading to hires.

## Reporting that is useful at tax time

Recommendation: start with payment reconciliation and accountant-ready exports.
Crewbase currently knows postings, applications, assignments, and posted pay
ranges. These do not establish actual payments. Its Stripe subscriptions are
payments for Crewbase plans, not wages paid to crew.

For U.S. businesses, employee wages generally belong on Form W-2; qualifying
nonemployee compensation is reported through Form 1099-NEC. Worker classification
is not determined by a posting's “contract” employment type. Reporting rules also
depend on the payment method and tax year. Do not derive tax forms from estimated
rates multiplied by scheduled days.

Suggested reporting phases:

1. **Work activity export:** completed gigs, roles, work dates, and company/crew
   identifiers. Label it as activity, with no implication that wages were paid.
2. **Payment ledger:** import from a payroll/accounting provider or record
   externally paid amounts, including legal payer/payee, payment date, currency,
   gross compensation, reimbursements, payment method, source identifier,
   supporting reference, reconciliation status, and corrections/reversals.
   Deduplicate imports and retain an audit trail. A booking is never an automatic
   payment record. Actual hours and approved expenses can be a later input.
3. **Year-end reconciliation:** totals by payee, company, currency, and payment
   year; compensation and reimbursements shown separately; missing payroll/vendor
   records, unmatched payments, and unverified entries flagged for review.
   Do not combine currencies or assume a reimbursement's tax treatment.
4. **Accountant/payroll exports:** detail and summary CSVs with consistent IDs,
   date range and generation timestamp, reconciliation totals, and spreadsheet
   formula-injection protection. Company ownership and export access must be
   enforced, with sensitive exports logged.
5. **Provider integration:** let a payroll or tax-filing provider produce and file
   W-2/1099 forms once payment data and worker records are reconciled. Prefer a
   provider-hosted process for W-9/tax identifiers; do not collect SSNs in network
   profiles, shared notes, messages, or generic job attachments.

Validate jurisdiction and the target customer's payroll workflow before building
form-specific reporting. The company/accountant must review classification and
reportability. Thresholds and rules must be versioned by tax year, not hardcoded
from a previous year's assumptions. Payment-card/third-party-settlement rules can
affect which party reports a payment and require reconciliation to avoid double
reporting.

Primary references reviewed September 24, 2026:

- [IRS: Forms and associated taxes for independent contractors](https://www.irs.gov/businesses/small-businesses-self-employed/forms-and-associated-taxes-for-independent-contractors)
- [IRS: Employment tax recordkeeping](https://www.irs.gov/businesses/small-businesses-self-employed/employment-tax-recordkeeping)
- [IRS: Independent contractor or employee](https://www.irs.gov/businesses/small-businesses-self-employed/independent-contractor-self-employed-or-employee)
- [IRS: Instructions for Forms 1099-MISC and 1099-NEC](https://www.irs.gov/instructions/i1099mec)
