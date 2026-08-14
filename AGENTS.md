# Crewbase Engineering Guide

These rules apply to the entire repository. Prefer small, reviewable changes that
preserve existing behavior. When a rule conflicts with framework requirements,
security, accessibility, or correctness, document the exception in the code and
choose the safer implementation.

## Rails architecture

Keep request handling in controllers, domain behavior in models and cohesive
objects, and presentation in components.

- Controllers authenticate and authorize, normalize permitted parameters,
  coordinate domain operations, prepare render-ready data, and select a response.
- Models own associations, validations, scopes, and compact domain behavior that
  is intrinsic to one record or aggregate.
- Do not interpret "fat models" as permission for a massive model. Extract a
  cohesive PORO when logic has several branches, coordinates multiple aggregates
  or external systems, is reusable, or makes the model difficult to scan.
- Put orchestration and side effects in `app/services`, query composition in
  `app/queries`, presentation-only transformations in `app/presenters`, and
  reusable value objects in `app/models` or `app/lib` as appropriate.
- Put recommendation candidate selection, scoring, ranking, availability
  checks, and match explanations in dedicated recommender objects under
  `app/queries`. Controllers may invoke a recommender and pass its render-ready
  results to a view or component, but must not reproduce recommendation rules.
- Name objects after an outcome or concept, not a vague mechanism:
  `DashboardQuickSearch`, `ProfileCompletion`, `PublishJob`, not
  `ProfileHelperService` or `Manager`.
- Prefer one public entry point such as `call`, `results`, or `to_h`. Keep
  collaborators explicit through initializer arguments.
- Avoid callbacks for workflows involving other records or external services.
  Use an explicit service called by the controller/job. Small record-local
  normalization callbacks are acceptable.
- Put reusable query logic in named scopes or query objects. Eager-load
  associations used by a collection page to avoid N+1 queries.

As a review signal, investigate controllers or models approaching 200 lines.
Line count is not itself a reason to split a cohesive class, but large classes
must remain easy to navigate and test.

## Reuse and duplication

Search the repository before introducing new behavior. Do not duplicate logic
that already exists under a different controller, model, helper, component,
query, service, presenter, recommender, or JavaScript controller.

- Use `rg` to search for the domain term, UI copy, route, model method, and
  similar behavior before writing a new implementation.
- Reuse an existing public API when it already expresses the required behavior.
  If it is too narrowly named or located, generalize or relocate it with tests
  rather than creating a parallel implementation.
- Extract genuinely shared behavior into the appropriate boundary. Do not copy
  private methods between classes or duplicate calculations in views.
- Keep one source of truth for business constants, scoring weights, status
  rules, formatting policies, and authorization decisions.
- Before handoff, search again for equivalent implementations introduced or
  exposed by the change. Consolidate meaningful duplication while avoiding
  speculative abstractions for code used only once.

## Controllers

- Keep actions short and at one level of abstraction.
- Use `before_action` only for shared lookup, authorization, or truly common
  render preparation. Do not hide a multi-step business workflow in callbacks.
- Controllers may assign render-ready instance variables. Prefer a presenter or
  component input over many parallel instance variables describing one concept.
- Do not place reusable business rules, calculations, or multi-record write
  transactions in controllers.
- Use strong parameters and scoped lookups. Resolve ownership through the
  authenticated user or an authorized relation instead of loading globally and
  checking afterward.
- Extract repeated form collection preparation rather than duplicating the same
  joins and ordering across actions.

## HAML and views

HAML is declarative markup, not a query or business-logic layer.

- Never construct an Active Record query in HAML. Calls such as `where`,
  `joins`, `includes`, `order`, `limit`, `pluck`, `find`, and `exists?` belong
  in a controller, scope, query object, presenter, or component Ruby class.
- Do not reference model collections such as `Industry.all` in HAML. Pass the
  ordered collection into the view or component.
- Avoid nontrivial local assignment (`- value = ...`) in HAML. Prepare values
  before rendering or expose a clearly named component/presenter method.
- A tiny formatting identifier needed only by one repeated form control (for
  example, a DOM id derived from a form builder object name) is an acceptable
  exception when moving it to Ruby would obscure the markup. It must not query,
  mutate records, or encode a business rule.
- Accessing an already-loaded association and using in-memory collection
  methods such as `first`, `map`, `any?`, or `length` is acceptable. Controllers
  must preload collection-page associations.
- Keep conditionals about presentation state shallow. Move multi-branch policy,
  permissions, calculations, and status derivation to Ruby.
- Use two-space HAML indentation and one consistent hierarchy: page heading,
  section/container, row/grid, card, card body, content. Keep sibling sections
  at the same indentation level.
- Prefer semantic elements and Bootstrap utilities already used by the app.
  Preserve labels, keyboard behavior, ARIA attributes, and Turbo frame targets.
- Avoid inline styles when a reusable class conveys the same rule.

Example:

```ruby
# controller
@industries = Industry.order(:name)
@recent_reviews = profile.received_reviews.includes(profile: :user).recent.limit(3)
```

```haml
= render CompanyFormComponent.new(company: @company, industries: @industries)
- @recent_reviews.each do |review|
  ...
```

Do not write:

```haml
- industries = Industry.order(:name)
- profile.received_reviews.order(created_at: :desc).limit(3).each do |review|
```

## ViewComponents and partials

Use ViewComponent for reusable UI and for complex page sections. The goal is a
page template whose major sections and data dependencies are obvious.

- New reusable or nontrivial UI belongs in `app/components`, with the Ruby class
  and `.html.haml` template under the same namespace.
- Give every component explicit inputs. It must not issue database queries or
  reach through unrelated global state. `current_user` is acceptable only when
  authorization-specific presentation cannot be expressed as a clearer input.
- Test component behavior in `test/components` with rendered HTML assertions.
- Do not render one ViewComponent directly inside another ViewComponent.
  Composition is allowed only through an explicit `renders_one` or
  `renders_many` slot populated by the caller. Slots keep dependencies visible
  and prevent hidden component trees.
- Page templates may render multiple sibling components.
- Never render a partial from inside another partial.
- Do not add new application partials. Convert reusable application partials to
  ViewComponents when touching them. Framework-owned Devise/Action Text
  extension points may remain partials when the framework requires those paths.
- Existing layout partials are migration debt: convert them deliberately rather
  than combining their conversion with unrelated feature work.
- A component should not merely rename a one-line helper call. Extract a
  component when it owns structure, variants, behavior, or a reusable visual
  contract.

Slot composition example:

```ruby
class CardComponent < ApplicationComponent
  renders_one :header
  renders_one :body
end
```

```haml
= render CardComponent.new do |card|
  - card.with_header { "Experiences" }
  - card.with_body do
    = render ExperiencesComponent.new(experiences: @experiences)
```

## Testing and changes

- Use test-driven development for behavior changes and refactors: add a focused
  test, run it and confirm the expected failure, implement the smallest change,
  then run the focused test and relevant regression tests.
- Model tests cover validations, scopes, and domain behavior. Service/query tests
  cover branching and orchestration. Component tests cover rendered structure
  and states. Controller tests cover authorization, status, redirects, and
  response integration.
- Do not assert private implementation details when an observable result is
  available.
- Add a regression test for every fixed bug.
- Run focused tests while iterating, then `bin/rails test` and
  `bin/rubocop` before handoff. Report any test that cannot run and why.
- Keep `test/architecture/view_boundary_test.rb` green. It prevents Active
  Record query construction in HAML and direct ViewComponent nesting.

## Marketing homepage

Treat the public marketing homepage as part of the product, not as a separate
one-time artifact.

- When adding, removing, or materially changing a user-facing capability,
  review the marketing homepage in the same change.
- Update homepage copy when the product's actual capabilities, terminology, or
  audience value proposition changes. Do not advertise unfinished features.
- Keep marketing claims concise, accurate, and consistent with the in-app
  experience. A product change does not require new homepage copy when it is too
  minor or implementation-specific to affect a visitor's understanding.

## Safe refactoring

- Preserve unrelated dirty-worktree changes.
- Avoid wholesale rewrites. Extract one cohesive responsibility at a time and
  keep behavior green between extractions.
- Do not change public routes, persisted data, authorization, or response shape
  as a side effect of a style refactor.
- When a legacy area cannot safely be migrated in the current task, record the
  concrete violation and a proposed boundary rather than partially converting
  it into a less consistent state.
