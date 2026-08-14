---
problem_type: feature_gap
component:
  - user_account_settings
  - notification_preferences
  - authenticated_navigation
symptoms:
  - users had no dedicated screen for updating account contact information
  - the profile and avatar menu had no settings entry point
  - notification channels and topics could not be selected independently
tags:
  - rails
  - account-settings
  - notification-preferences
  - view-component
  - authorization
---

# Account settings with notification channel and topic preferences

## Problem

Crewbase stored a user's name, email, and phone number but offered no central account-settings workflow. Users also could not record whether they wanted email or SMS or choose among job alerts, newly recommended roles, and upcoming-job reminders.

## Solution

Use a singular authenticated `usr/settings` resource whose controller reads and updates only `current_user`. Keep the permitted account and preference attributes explicit, and render validation failures with status `422`.

Store delivery channels separately from notification topics. This lets future delivery code require both kinds of consent, such as email being enabled and recommended-role notifications being enabled before sending a recommended-role email.

The database supplies non-null defaults: email and all three topics are enabled, while SMS is disabled. The `User` model requires a phone number whenever SMS is enabled. The form is a query-free ViewComponent with an explicit `user:` input, and links appear in the avatar dropdown and owner-only profile controls.

```ruby
resource :settings, only: [ :show, :update ]

if current_user.update(settings_params)
  redirect_to usr_settings_path, notice: "Settings updated."
else
  render :show, status: :unprocessable_entity
end
```

This feature captures preferences only. It does not add an SMS provider, scheduled reminder jobs, or make existing notification producers consult the new fields.

## Regression strategy

- Verify useful defaults at the model boundary.
- Reject SMS opt-in without a phone number.
- Exercise rendering, successful updates, atomic validation failures, authentication, and both navigation entry points in controller integration tests.
- Keep the endpoint scoped to `current_user` and its strong-parameter allowlist.
- When delivery is added, centralize the topic-and-channel decision in one policy object and test the complete channel/topic matrix.
- Treat transactional messages separately and decide explicitly whether each may bypass preference settings.

## Related solutions

- [Tiered crew recommendations](tiered-crew-recommendations.md)
- [Secure public job sharing and tokenized invitation auth handoff](../security-issues/secure-public-job-sharing-and-tokenized-invitation-auth-handoff.md)
