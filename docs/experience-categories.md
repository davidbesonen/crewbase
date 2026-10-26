# Occupations, confirmed categories, and specific experience

Crewbase keeps specific occupations and a bounded vocabulary of 94 work
capabilities/services plus 52 selectable equipment/software families. Twelve older
equipment umbrellas remain valid for existing selections and requirements. Brands, products, models, and
individual techniques are optional personal entries, not global catalog records.

## Profile configuration

Members select `capability_keys` and `equipment_family_keys`. Stable category
keys are validated against `ExperienceCategories`, which reads the current
definitions in `config/experience_categories.yml`. Historical migration catalogs
remain unchanged. Occupations remain
independent and searchable. Categories describe reported familiarity, not
verified qualifications or ownership of equipment.

Profile and job forms prioritize categories relevant to the selected occupations.
`OccupationExperienceCategories` reads `config/occupation_experience.yml`,
which separates each of the 61 maintained occupations' core duties from additional
work specialties and tool families. Core duties (and their broader categories)
appear in an “Included through occupations” note instead of selectable extras.
Multiple occupations combine their core duties and guidance. Other categories remain available for work
across disciplines, and saved selections always stay visible and removable. Unknown roles
fall back to all categories. Changing occupations updates guidance without
checking boxes, removing selections, or replacing unsaved personal details.
The core mapping supplies matching evidence without writing extra category keys.
Removing an occupation removes that inferred evidence, unless the member also
explicitly selected the category. Tool familiarity is never inferred from a role.
Core duties also satisfy the experience portion of profile completion; members
are not penalized for having no additional specialties or tool selections.
Search reaches available choices under Other categories without exposing core
duties or redundant parents of selected specialties. Suggestions follow the same rules.
The [industry and occupation audit](research/occupation-experience-audit.md)
records sources, design decisions and every occupation's suggested choices.

Profiles also retain `skills_text`, `equipment_text`, and optional `work_examples`.
The entry fields support 30 unique lines, 80 characters each, and 2,500 characters
total. Examples support 2,000 characters. Unknown products can always be entered.

Suggestions use bounded general work phrases and selected occupations. They do
not maintain a product/brand dictionary, use an external AI service, or interpret
arbitrary prose. An unfamiliar product name may yield no suggestion. Members can
choose directly from the category list regardless. Suggestions show their source
phrase, require an explicit Add action, and only persist with the normal profile
save. More specific suggestions suppress redundant parent suggestions.
Refreshing suggestions does not save any profile fields. Suggestions never
feed the recommender as confirmed experience.

## Jobs and recommendations

Employers select required/preferred capabilities and equipment families, using
the same keys as profiles. Named requirements remain separate text fields. Public
and signed-in job details distinguish broad categories from specific requirements.
Use broad fields when transferable experience is sufficient and named fields only
when a specific technique, product, or model matters.

`ExperienceMatch` is shared by worker and employer recommendations. Confirmed
category keys and conservatively mapped occupation core duties match regardless
of the wording in personal details. An explicitly selected or occupation-core
specialty also matches its explicitly configured broader family, but never the
reverse or a neighboring specialty. For example, monitor mixing is audio
experience; Audio production alone does not satisfy Monitor mixing. Overlapping
family/specialty matches count once in scoring, including unstructured postings.
FOH Engineer supplies front-of-house mixing, but not monitor mixing or console
familiarity. Technical Director supplies leadership, but not broadcast switching
or theatre staging; these remain explicit specialties. A broad acting category
does not satisfy a specifically named voiceover requirement.
For example,
“live sound mixing” and “live audio mixing” can both accompany the confirmed
Audio production category. A category does not substitute for a named product:
Audio systems cannot satisfy a DiGiCo SD7 requirement.

Specific entries still use normalized whole-entry comparisons: case, Unicode
width, and whitespace are ignored; punctuation and product identities remain
significant. No synonym or product equivalence is inferred. Optional examples
and prose do not fulfill requirements. Duplicate required/preferred matches of
the same type and name do not inflate scores.

Worker recommendations exclude jobs with missing required experience. Employer
recommendations retain full/near-match tiers: one missing requirement or known
availability conflict can appear with an explicit gap; more than one excludes
the candidate. Occupations, relevant work history, reviews, location, and known
availability retain their existing roles. Location alone is not relevant work
experience. Jobs without explicit requirements can use whole-phrase mentions of
selected category labels and named experience in their title/description.

The people directory supports partial searches over personal entries and category
labels, including occupation core duties. Job-specific crew search filters recommendations by normalized category
labels or whole personal entries.

## Existing data and rollout

Deploy with `bin/rails db:migrate`; do not run destructive demo seeds to migrate an
existing installation. Personal-entry migrations preserve original records and
copy previously selected names. Null detail fields fall back to original
associations; explicit empty strings suppress that fallback.

The confirmed-category migration preserves active, explicitly selected broad
categories from the earlier rollout. It does not infer categories from individual
products, occupations, or prose, nor reactivate a selection cleared from personal
entries. All other profiles can confirm suggestions or select categories directly.
Original assignments and requirements remain available. Rollbacks refuse to
discard new personal entries or confirmations.

Historical migrations/catalogs remain versioned. New choices of occupation use
`db/catalogs/occupations_v2.rb` and `InstallOccupationCatalog`. Category keys stay
stable; expand the vocabulary only for meaningfully distinct transferable work,
not individual products. Demo seeds illustrate confirmed categories and optional
details without expanding Skill or Equipment catalogs.
