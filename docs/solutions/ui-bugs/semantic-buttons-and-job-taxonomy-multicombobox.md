---
problem_type: ui_consistency_feature
component: shared buttons and job taxonomy multi-select controls
symptoms:
  - inconsistent visual hierarchy and sizing across button actions
  - global button styling could override Bootstrap size variants
  - large job taxonomy fields lacked type-ahead and efficient keyboard multi-selection
tags:
  - rails
  - bootstrap
  - stimulus
  - accessibility
  - design-system
  - combobox
---

# Semantic buttons and job taxonomy multi-comboboxes

## Context

CrewBase needed a predictable button hierarchy and scalable job-requirement
inputs. Cyan secondary buttons were being used for both meaningful accent states
and routine navigation, while the shared `.btn` rule risked overriding
Bootstrap's small and large sizing. The job form also exposed five large
occupation, skill, and equipment collections as native multi-selects.

## Button system

Keep cross-cutting behavior in
`app/assets/stylesheets/colors.scss`, but leave padding and font size to
Bootstrap's `.btn-sm`, default, and `.btn-lg` variants.

Use semantic roles consistently:

- `.btn-primary`: the principal submit or forward action.
- `.btn-outline-primary`: constructive secondary actions such as Add or Edit.
- `.btn-quiet`: Back, Cancel, Clear, View, and other neutral navigation.
- `.btn-outline-danger`: ordinary destructive actions.
- `.btn-secondary`: accent or selected states, not generic neutral actions.

The shared system also defines `:focus-visible` and disabled states,
`.btn-icon` square sizing, and `.btn-group-responsive` wrapping.

`test/stylesheets/button_system_test.rb` protects the Bootstrap size boundary
and the presence of semantic roles. Component tests should assert roles when a
screen combines neutral, constructive, and destructive controls.

## Job taxonomy multi-combobox

`Usr::Company::JobFormComponent#taxonomy_requirement_fields` is the single
configuration source for:

- required occupations;
- required skills;
- preferred skills;
- required equipment;
- preferred equipment.

The component sorts each collection case-insensitively and restores selections
from persisted requirements or submitted parameters after a validation error.
Each control renders removable chips and an accessible search/listbox interface
backed by a visually hidden native `<select multiple>`. The native control keeps
the existing `job[..._ids][]` parameter shape, and a blank hidden field ensures
that clearing every selection is submitted explicitly.

`taxonomy_multiselect_controller.js` synchronizes the native options, chips,
listbox selection, checkmarks, ARIA state, and live result count. It supports:

- case-insensitive filtering;
- mouse selection;
- Arrow Up and Arrow Down navigation;
- Enter selection and Space selection when an option is highlighted;
- Escape to close;
- Backspace on an empty query to remove the last chip;
- click-outside dismissal.

The control selects existing taxonomy records; it does not create free-form
skills or equipment.

Keep styling scoped in `_taxonomy_multiselect.scss`. Do not place database
queries in the component or HAML: controllers provide ordered collections, and
the component performs only presentation-level sorting and selection mapping.

## Regression coverage

- `test/components/usr/company/job_form_component_test.rb` covers all five
  controls, alphabetical options, selected chips, ARIA selection, native Rails
  fields, and semantic button roles.
- `test/controllers/usr/company_job_requirements_test.rb` covers persistence,
  clearing/replacement, form integration, and validation-error selections.
- `test/architecture/view_boundary_test.rb` keeps queries and hidden component
  composition out of HAML.

For future expansion, add a browser/system test covering keyboard-only
selection and submission, duplicate prevention, no-match behavior, and long
chip wrapping at desktop and mobile widths.
