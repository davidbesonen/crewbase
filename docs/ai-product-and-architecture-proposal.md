# Crewbase AI Product and Architecture Proposal

Status: proposal only  
Date: July 25, 2026  
Scope: writing assistance and job-fit insights  
Non-goal: this document does not add an API client, make model calls, or automate employment decisions.

## Executive recommendation

Crewbase should introduce AI in two deliberately separate products:

1. **Writing assistance** for experience summaries, profile bios, and company descriptions. The user supplies the facts, requests a draft or revision, reviews the result, and explicitly applies it. AI never saves directly.
2. **Job-fit insights** built on deterministic filtering and scoring. AI may extract proposed requirements from a job description, rerank a small candidate set, and explain a match, but it must not decide who is qualified, hide jobs, reject applications, or infer protected/sensitive traits.

The first release should be the experience-summary assistant. It is low risk, bounded, measurable, and fits the existing Action Text experience editor. Before job recommendations, add structured requirements to `Job`; today Crewbase has structured candidate occupations, skills, equipment, locations, and availability, but job requirements exist only in `Job#description`.

Use the OpenAI Responses API behind a provider-neutral Rails boundary, request schema-constrained structured output, set `store: false` by default, enqueue non-interactive work through Active Job, and keep all persisted AI artifacts auditable and deletable. Model names must be configuration, not application constants.

## Existing Crewbase capabilities

The proposal is grounded in the current repository:

- `Profile` belongs to `User` and has occupations, skills, equipment, locations, experiences, and calendar events.
- `Profile#bio` is plain text.
- `Experience#summary` is Action Text rich text and an experience may optionally link to a database `Company`.
- `Company#description` is plain text.
- `Job#description` is Action Text rich text.
- Jobs already contain workplace type, employment type, travel, visa sponsorship, compensation, dates, status, company, and locations.
- Jobs do **not** currently have occupation, skill, equipment, industry, experience-level, certification, or explicit schedule requirements.
- Availability currently represents blockout events or an iCalendar feed. It is not a declaration that every unblocked day is available.
- The dashboard currently labels the five newest published jobs as “Recommended”; it does not rank them for the profile.
- Existing authorization correctly scopes profile editing to the owning user and company/job management to company owners. AI endpoints must preserve those boundaries.
- Action Text and Trix already provide a suitable insertion surface for experience summaries and job descriptions.
- Active Job is already used for calendar-feed work, so asynchronous AI generation and recommendation refreshes fit the application.

## Product principles

### Assist, never impersonate

Generated text is always a suggestion. The UI must label it as AI-generated, show the result before insertion, and require “Use this draft” or “Replace selection.” The author remains responsible for factual accuracy.

### Evidence before prose

The assistant should draft only from facts the user supplied in the current field or selected from their Crewbase records. It must not invent employers, dates, clients, equipment, achievements, revenue, audience size, credentials, or numerical outcomes.

### Matching is guidance, not adjudication

“Good fit” means a transparent comparison between user-controlled profile data and employer-entered job requirements. It must never be presented as a hiring score or probability of success.

### Deterministic facts, AI language

Code should own permissions, eligibility, filters, dates, distances, availability overlaps, exact taxonomy matches, score arithmetic, and persistence. AI may own drafting, normalization suggestions, semantic comparison, and plain-language explanations.

### Graceful absence

Every screen remains usable when AI is disabled, rate-limited, slow, unavailable, or declined by the user.

## Product 1: writing assistants

### Shared interaction

Add an `Ai::WritingAssistantComponent` adjacent to—not inside—the editor. It can be configured for `Experience`, `Profile`, or `Company`.

The component should offer:

- “Help me write” when the field is empty.
- “Improve writing” when text exists.
- Optional intent choices: concise, detailed, professional, or fix spelling/grammar.
- A fact prompt appropriate to the field.
- A preview panel with “Use this draft,” “Try again,” and “Cancel.”
- A visible reminder to verify names, dates, and accomplishments.
- No automatic submission of the parent form.

Preserve the user’s existing content until they explicitly apply a suggestion. Applying the draft only updates the browser editor; the existing profile/company form remains the sole persistence path.

### Experience summary

Current surface:

- `Usr::ProfileConfig::ExperienceFormComponent`
- nested `Experience` fields
- Action Text `summary`

Useful context:

- role/title
- company name
- start/end dates and current-role state
- user-selected skills and equipment
- the current summary, if any
- optional user-supplied responsibilities, tools, collaborators, and outcomes

Do not send unrelated experiences by default. A later opt-in “Use my other experiences for tone” option can include short excerpts.

Suggested UX copy:

> Describe what you did, the tools you used, and results you can verify. AI will organize your facts without inventing details.

The structured response should contain:

```json
{
  "suggestion_html": "<p>...</p>",
  "claims_to_verify": ["..."],
  "missing_details": ["..."],
  "safety_flags": []
}
```

Allow only the small Action Text subset Crewbase supports, sanitize the HTML server-side, cap length, and reject links or attachments in generated output.

### Profile About / bio

Current surface:

- `Usr::ProfileConfig::BioFormComponent`
- `Profile#bio` plain text

Useful context:

- occupations
- skills and equipment
- location at city/state/country granularity
- selected experience titles and company names
- headline and public links
- user-entered goals or preferred kinds of work

Do not include contact email, phone, date of birth, calendar-feed URL, IP/visit history, review author identities, or private company information.

The assistant should produce first-person prose because the profile is authored by the user. A useful limit is 80–160 words. Keep `Profile#bio` as plain text for the first release unless product requirements call for formatting; do not make a data migration just to support the assistant.

Response:

```json
{
  "suggestion_text": "...",
  "claims_to_verify": [],
  "missing_details": [],
  "safety_flags": []
}
```

### Company description

Current surface:

- `Usr::Company::CompanyDetailsFormComponent`
- `Company#description` plain text

Only company owners may request or apply suggestions. Context may include:

- company name
- public industries
- public location
- founded date
- public website
- existing description
- owner-entered services, clients, differentiators, and work culture

Do not infer company size from Crewbase assignments or invent customers, awards, safety records, financial claims, or diversity claims.

Suggested response length: 75–180 words. Keep this field plain text initially.

### Writing request flow

```text
User clicks AI action
  -> Stimulus opens the assistant panel
  -> POST /usr/ai/writing_suggestions
  -> controller authorizes the target record and validates allowed context
  -> Ai::WritingSuggestionRequest records consent, prompt version, and target
  -> Ai::GenerateWritingSuggestionJob or synchronous service calls provider
  -> structured response is schema-validated and sanitized
  -> Turbo Stream renders preview
  -> user applies preview to editor
  -> user saves the normal profile/company form
```

For the first release, use a synchronous request with a strict timeout if p95 latency is acceptable. If not, return `202 Accepted`, enqueue a job, and update via polling or Turbo Streams. Do not hold a Rails web worker for a long-running retry loop.

## Product 2: job-fit insights

### First fix the job data model

Reliable matching cannot come from prose alone. Add structured employer inputs:

- target occupations
- required skills
- preferred skills
- required equipment
- preferred equipment
- minimum experience years, optional
- date range and/or schedule requirements
- location radius or remote eligibility
- travel requirement already exists
- employment and workplace types already exist

Use existing `Occupation`, `Skill`, `Equipment`, and polymorphic assignment patterns where practical. Required/preferred intent needs an explicit attribute on the assignment or separate requirement records.

Recommended model:

```text
JobRequirement
  job_id
  requirement_type  # occupation, skill, equipment
  requirement_id    # taxonomy record ID
  importance        # required, preferred
  source            # employer, ai_suggested
  confirmed_at
  timestamps
```

A polymorphic `requirement` association is preferable to raw type/id handling in application code. Add unique indexes on job, requirement type/id, and importance as appropriate.

For AI extraction from job descriptions:

1. Parse a plain-text copy of `Job#description`.
2. Ask for proposed taxonomy matches and unresolved free text.
3. Map suggestions only to server-supplied taxonomy IDs.
4. Show them to the company owner.
5. Save only employer-confirmed requirements.

Never silently convert model extraction into a hard requirement.

### Candidate generation: deterministic

Start with all active, published jobs that the profile can view, excluding jobs already filled/closed/archived and optionally jobs already applied to.

Apply hard filters only when explicitly configured:

- application deadline has not passed
- a required date does not overlap a known user blockout
- on-site/hybrid geography is within an employer-defined radius, if both sides have sufficient location data
- any truly required job taxonomy items

An absence of availability data is “unknown,” not “available.” An absent profile location is “unknown,” not a mismatch.

### Baseline scoring: deterministic and explainable

Use a versioned weighted score before adding any model reranking. Example:

| Signal | Suggested weight | Rule |
| --- | ---: | --- |
| Occupation overlap | 30 | Set overlap, with required mismatch separately flagged |
| Required skill coverage | 25 | Covered required skills / required skills |
| Preferred skill overlap | 10 | Jaccard or coverage score |
| Equipment coverage | 10 | Required and preferred treated separately |
| Experience relevance | 10 | Title/taxonomy overlap and duration, capped |
| Availability | 10 | No known conflict; unknown receives neutral score |
| Location/workplace | 5 | Remote/full match or distance band |

Normalize to 0–100, but display user-facing bands such as “Strong match,” “Potential match,” and “Explore” rather than a false-precision percentage during early rollout.

Return evidence with every score:

```json
{
  "score": 82,
  "band": "strong_match",
  "matched_skill_ids": [12, 45],
  "missing_required_skill_ids": [],
  "matched_equipment_ids": [8],
  "availability_state": "no_known_conflict",
  "location_state": "remote",
  "score_version": "v1"
}
```

This layer is cheap, fast, testable, and works with AI turned off.

### Optional semantic reranking

Once baseline quality is measured, add semantic relevance to a small candidate set:

- Build a redacted profile representation from public professional data.
- Build a job representation from confirmed structured requirements and description.
- Create embeddings asynchronously when the source data changes.
- Retrieve or rerank only the top deterministic candidates.
- Blend semantic similarity as a small, capped feature rather than replacing the baseline.

An initial formula could reserve no more than 10–15% of the final score for semantic similarity. Version every formula and retain component evidence.

PostgreSQL currently does not show a vector extension or vector columns. Decide between:

- `pgvector` in the existing database; or
- provider-hosted/private retrieval infrastructure.

For this app’s current scale and Rails architecture, `pgvector` is likely the simpler operational choice, but it must be approved based on hosting support. Do not introduce it until measured lexical/taxonomy matching proves insufficient.

### AI explanation layer

Generate explanations only for the top few jobs, on demand or asynchronously:

```json
{
  "headline": "Strong audio-production overlap",
  "reasons": [
    {
      "kind": "skill",
      "text": "Your live sound and audio engineering skills match two listed needs.",
      "profile_evidence_ids": ["skill:12", "skill:45"],
      "job_evidence_ids": ["job_requirement:91", "job_requirement:92"]
    }
  ],
  "gaps": [
    {
      "kind": "equipment",
      "text": "The listing prefers Dante certification, which is not on your profile.",
      "job_evidence_ids": ["job_requirement:95"]
    }
  ],
  "caveat": "This comparison uses the information currently listed in your profile."
}
```

Validate every cited ID against the records sent to the model. If evidence does not resolve, drop that sentence. AI prose must not change the deterministic score.

### Dashboard experience

Replace the current recency-only “Open Jobs (Recommended)” behavior in stages:

1. Rename it “Open Jobs” until actual ranking is enabled.
2. With deterministic v1 enabled, show “Jobs that match your profile.”
3. On each card show the match band and two evidence-backed reasons.
4. Add “Why this match?” to expand score components and known gaps.
5. Add “Not relevant” feedback with optional reason:
   - wrong role
   - wrong location
   - unavailable dates
   - missing qualification
   - not interested
6. Let the user turn personalized recommendations off.

Never suppress access to the complete jobs index. Recommendation ranking is a convenience, not a gate.

## Architecture

### Provider-neutral boundary

Do not call an AI SDK from controllers, models, components, or views. Introduce a narrow boundary:

```text
Ai::Client
Ai::Response
Ai::Errors::{Timeout, RateLimited, InvalidOutput, Refused, Unavailable}

Ai::GenerateWritingSuggestion
Ai::ExtractJobRequirements
Ai::ExplainJobMatch

JobMatching::CandidateFinder
JobMatching::Score
JobMatching::Ranker
JobMatching::ProfileSnapshot
JobMatching::JobSnapshot
```

`Ai::Client` owns HTTP/provider details. Domain services own context construction, schemas, authorization-independent business rules, prompt versions, and validation.

Use direct HTTPS or an officially supported SDK selected during implementation. No gem should dictate the domain interface.

### Suggested persistence

`ai_requests`:

- `user_id`
- `request_type`
- polymorphic target
- `status`
- `prompt_version`
- `model`
- `input_digest`
- `provider_request_id`
- token/usage counts
- latency
- error code
- `consent_version`
- timestamps

Do **not** persist raw prompt bodies or generated text here by default. Store the accepted text only in its normal domain field. For short-lived debugging, use encrypted, access-restricted samples with an explicit retention window and production sampling off by default.

`job_match_scores`:

- `profile_id`
- `job_id`
- `score`
- `band`
- `components` JSONB
- `score_version`
- source data fingerprints
- `calculated_at`
- unique index on profile/job/score version

`ai_feedback`:

- `user_id`
- polymorphic subject
- `feature`
- `rating` or reason enum
- optional sanitized comment
- prompt/model/version metadata
- timestamps

Add embedding columns/tables only in the semantic-ranking phase.

### Endpoints

Proposed routes:

```ruby
namespace :usr do
  namespace :ai do
    resources :writing_suggestions, only: :create
    resources :job_requirement_suggestions, only: :create
    resources :job_match_explanations, only: :show
    resources :feedback, only: :create
  end
end
```

Authorization:

- Experience and profile suggestions: target profile must belong to `current_user`.
- Company suggestions and requirement extraction: `current_user` must be the company owner.
- Match explanations: profile must belong to `current_user`; job must be visible and published.
- Never accept arbitrary target type names, record IDs, context, prompt text, or model IDs from the browser.
- Re-fetch and serialize all context on the server.

### Jobs

Likely jobs:

- `Ai::GenerateWritingSuggestionJob`
- `Ai::ExtractJobRequirementsJob`
- `JobMatching::RefreshProfileMatchesJob`
- `JobMatching::RefreshJobMatchesJob`
- `Ai::GenerateJobMatchExplanationJob`

Trigger refreshes after committed changes to:

- profile occupations, skills, equipment, location, experience, or availability
- job requirements, location, dates, workplace type, status, or description

Prefer debounced/coalesced jobs keyed by profile/job. Do not enqueue one model call per candidate job.

### Structured outputs

Use JSON Schema-constrained output for every machine-consumed response. Schema validation is still followed by domain validation:

- maximum string and array lengths
- allowed enum values
- referenced IDs exist and were in the request
- generated HTML is sanitized
- no unexpected URLs or attachments
- refusal and incomplete-output states are handled

Structured outputs make shape reliable; they do not make claims true.

### Prompt versioning

Store prompts as versioned Ruby objects or YAML under `config/ai_prompts/`, with tests. Each prompt should state:

- task and audience
- permitted evidence
- facts the model must not invent
- desired tone/length
- exact output schema
- instruction to expose uncertainty and missing information

Keep stable instructions and schemas at the beginning of requests so repeated prefixes can benefit from provider prompt caching. Do not include secrets or unnecessary personal data in cached prefixes.

## Privacy, consent, and user control

Before first use, explain:

- which Crewbase fields will be sent
- that a third-party AI provider processes the request
- that suggestions may be inaccurate
- that use is optional

Record a versioned consent timestamp. Provide a setting to disable personalized AI and a path to delete AI request metadata and feedback, subject to legal/audit requirements.

Data minimization rules:

- send professional facts required for the current task only
- never send passwords, auth tokens, calendar-feed URLs, IP addresses, date of birth, private contact details, or unrelated review content
- use city/state/country rather than street address for matching
- send availability as bounded conflict facts, not raw calendar event names
- do not send data about other users
- set `store: false` unless a reviewed product requirement needs provider-side state
- verify the selected provider/project’s retention and data-control configuration before launch

Crewbase should update its privacy policy and in-product disclosure before production enablement.

## Safety, fairness, and employment boundaries

Job matching affects employment opportunities, so:

- do not use or infer age, date of birth, race, ethnicity, religion, sex, gender, disability, health, family status, or other protected/sensitive traits
- do not infer traits from names, photos, locations, biographies, or social links
- do not use reviews or reviewer sentiment as a recommendation feature
- do not rank by profile photo presence, company prestige, name recognition, or writing polish
- do not let employers sort applicants by AI fit score in the initial product
- do not automatically reject, screen, shortlist, notify, or contact anyone
- show users the source fields behind a recommendation and let them correct those fields
- audit score and exposure distributions for unjustified disparities
- have counsel review applicable employment and automated-decision laws before expanding into employer-facing ranking

Moderation can screen user-entered AI instructions and generated prose, but it does not replace authorization, sanitization, or employment-law controls.

## Prompt injection and untrusted content

Treat profile, company, experience, and job prose as untrusted data, never as instructions.

- delimit user/domain text as data
- do not expose tools to writing-assistant calls
- do not allow generated content to select routes, records, or permissions
- never render model HTML without Rails sanitization
- strip scripts, event attributes, unsupported tags, external images, and unsafe links
- constrain taxonomy selection to server-provided IDs
- do not follow URLs found in descriptions

## Cost and latency controls

- Configure model per task via credentials/environment.
- Start with a fast, lower-cost model that supports structured output; promote only measured hard cases to a stronger model.
- Cap input and output tokens and truncate context by explicit domain rules.
- Writing assistance: one request at a time per user, short timeout, bounded retry for transient failures only.
- Explanations: generate on demand or for only the top dashboard results.
- Requirement extraction and embeddings: asynchronous and deduplicated by source digest.
- Cache accepted deterministic scores until relevant fingerprints change.
- Use prompt caching for stable instructions and schemas when request volume justifies it.
- Consider Batch API only for non-urgent backfills/evaluation—not interactive writing assistance.
- Set per-user, per-company, and global rate/spend limits.
- Add a feature kill switch independent of deployment.

Track cost per successful accepted suggestion and per recommendation engagement, not just cost per request.

## Failure and fallback behavior

| Failure | User behavior |
| --- | --- |
| Timeout/provider outage | Keep original text; “AI help is temporarily unavailable.” |
| Rate limit | Keep editor usable; advise retry later without automatic loops. |
| Refusal | Explain that no draft was produced; do not expose raw provider internals. |
| Invalid schema | Log safe metadata, retry once if appropriate, then fail closed. |
| Unsafe output | Do not show or insert it; offer ordinary editing. |
| Missing profile data | Ask for specific facts or link to the relevant profile section. |
| No structured job requirements | Show recent/open jobs, not fake personalized ranking. |
| Stale match | Recalculate or label it stale; never reuse across source fingerprint changes. |

## Observability

Record:

- feature, prompt version, model, provider request ID
- status/error category
- latency and queue time
- input/output/cached token usage
- estimated cost
- retry count
- structured-output validation failures
- suggestion previewed/applied/discarded/edited
- recommendation viewed/clicked/applied/dismissed
- score version and component distribution

Never put raw profile/job prose, prompts, model responses, API keys, contact data, or calendar details in ordinary logs. Use request IDs to correlate Rails logs with provider dashboards.

Set alerts for elevated error rate, latency, spend, invalid output, refusal rate, and recommendation coverage collapse.

## Evaluation

### Writing assistant evaluation set

Build consented or synthetic cases across occupations and experience levels. Human reviewers score:

- factual consistency
- invention rate
- preservation of user voice
- grammar/readability
- specificity
- appropriate length
- safe HTML

Hard failure: any unsupported employer, date, credential, client, metric, or accomplishment.

Product measures:

- preview-to-apply rate
- amount edited after insertion
- save completion rate
- retry/discard rate
- user-reported inaccuracy

High acceptance alone is not proof of quality.

### Matching evaluation set

Before AI reranking, create labeled profile/job pairs with domain reviewers. Measure:

- precision/recall at dashboard `k`
- nDCG or ranking agreement
- required-skill mismatch rate
- availability conflict rate
- explanation evidence validity
- coverage for incomplete profiles
- stability under irrelevant prose changes

Counterfactual tests must confirm that changing a name, photo, date of birth, or other excluded attribute cannot alter a score.

Compare:

1. recency baseline
2. deterministic taxonomy score
3. deterministic plus lexical similarity
4. deterministic plus embeddings
5. optional model reranking

Ship the simplest approach that meets the quality threshold.

## Testing strategy

### Unit tests

- profile/job snapshot redaction
- score components and weights
- date overlap and “unknown” availability
- location bands and remote behavior
- prompt/schema builders
- output validators and HTML sanitizer
- source fingerprints
- consent and quota checks

### Model/service contract tests

- stub HTTP at the `Ai::Client` boundary
- valid response, refusal, incomplete output, timeout, 429, 5xx, malformed JSON
- unknown taxonomy IDs are rejected
- generated unsupported HTML is removed
- provider request IDs and usage metadata are captured
- no raw sensitive values appear in logged payloads

Do not make live provider calls in the normal Rails test suite.

### Controller/request tests

- unauthenticated access redirects/rejects
- users cannot request suggestions for another profile
- non-owners cannot request company/job assistance
- unpublished/invisible jobs cannot be explained
- browser-provided context/model/prompt is ignored
- rate limiting and consent enforcement

### Component/system tests

- original text survives generation failures
- preview does not mutate the field until accepted
- apply, retry, cancel, keyboard, focus, and screen-reader states
- rich-text insertion and sanitization
- dashboard reasons and “Why this match?”
- opt-out and non-AI fallback

### Offline evals

Version datasets, prompt versions, model configuration, graders, and thresholds. Run evals before prompt/model/weight changes and as a deployment gate for recommendation changes.

## Phased rollout

### Phase 0: instrumentation and decisions

- Rename recency-only “Recommended” dashboard copy.
- Decide provider/project, data controls, retention, legal/privacy copy, spend ceiling, and hosting support for vector search.
- Add feature flags and metrics vocabulary.
- Build synthetic evaluation sets.

### Phase 1: experience writing assistant

- Add provider-neutral client and structured response validation.
- Add consent, rate limits, audit metadata, component, endpoint, and tests.
- Roll out internally, then to a small opt-in cohort.

### Phase 2: profile and company assistants

- Reuse the shared component with target-specific context builders and prompts.
- Add owner authorization for companies.
- Measure factuality and acceptance separately by feature.

### Phase 3: structured job requirements

- Add job requirement records and owner confirmation UI.
- Optionally extract suggestions from descriptions.
- Do not yet change job ranking.

### Phase 4: deterministic recommendations

- Add score service/cache and dashboard evidence.
- Add opt-out and relevance feedback.
- Compare against recency baseline.

### Phase 5: semantic relevance and explanations

- Introduce embeddings only if measured need exists.
- Cap semantic influence.
- Generate evidence-bound explanations for top results.

### Phase 6: controlled optimization

- Tune weights/prompts from evals and aggregate feedback.
- Consider asynchronous batch refreshes.
- Do not add employer-facing applicant ranking without separate legal, fairness, and product review.

## Likely repository changes by phase

Writing assistance:

- `app/clients/ai/client.rb`
- `app/services/ai/generate_writing_suggestion.rb`
- `app/services/ai/context_builders/*`
- `app/services/ai/output_validators/*`
- `app/components/usr/ai/writing_assistant_component.*`
- `app/controllers/usr/ai/writing_suggestions_controller.rb`
- `app/javascript/controllers/ai_writing_assistant_controller.js`
- `app/jobs/ai/generate_writing_suggestion_job.rb` if async
- migration/model for `AiRequest` and AI preferences/consent
- routes and focused tests

Matching:

- migration/model for `JobRequirement`
- job form ViewComponent changes
- `app/services/job_matching/*`
- refresh jobs
- match-card/reason ViewComponents
- migration/model for `JobMatchScore`
- optional embedding storage in a later phase

## Decisions and blockers

Required before implementation:

1. Which AI provider and account/project will process production data?
2. Which data-retention/data-residency controls are contractually required?
3. What exact consent and privacy-policy language is approved?
4. What monthly and per-user spend ceilings should the feature enforce?
5. Should AI be available to all plans or gated by a company/user plan?
6. Which job attributes are truly “required” versus “preferred”?
7. How should geographic distance work, and is geocoding available/approved?
8. Is an unblocked calendar date neutral or positive? Recommendation: neutral.
9. Does production PostgreSQL support `pgvector` if semantic retrieval is later justified?
10. Who owns the labeled evaluation set and fairness review?

No technical blocker prevents a small experience-writing-assistant pilot after items 1–4 are decided. Reliable personalized job ranking is blocked on structured job requirements and product definitions for availability and location.

## Official OpenAI references

- [Responses API migration and rationale](https://developers.openai.com/api/docs/guides/migrate-to-responses)
- [Structured model outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
- [Vector embeddings](https://developers.openai.com/api/docs/guides/embeddings)
- [Data controls in the OpenAI platform](https://developers.openai.com/api/docs/guides/your-data)
- [Prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching)
- [Batch API](https://developers.openai.com/api/docs/guides/batch)
- [Working with evals](https://developers.openai.com/api/docs/guides/evals)
- [Moderation](https://developers.openai.com/api/docs/guides/moderation)
- [Safety best practices](https://developers.openai.com/api/docs/guides/safety-best-practices)
- [Production best practices](https://developers.openai.com/api/docs/guides/production-best-practices)

