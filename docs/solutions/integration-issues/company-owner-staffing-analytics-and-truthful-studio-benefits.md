---
problem_type: integration_feature
component:
  - company_manager
  - staffing_analytics
  - pricing_entitlements
  - company_visibility
symptoms:
  - Studio pricing promised analytics and visibility without a concrete owner-facing surface
  - company staffing data was spread across jobs, applications, invitations, projects, and assignments
  - company management analytics required strict owner scoping
tags:
  - rails
  - view-component
  - chart-js
  - authorization
  - pricing
  - analytics
---

# Company owner analytics and truthful Studio benefits

Pricing copy must map to behavior a customer can actually find and use. The Studio plan advertised staffing analytics, enhanced visibility, priority support, and early integration access, but only the underlying staffing workflows existed.

## Solution

Add an owner-scoped company manager route and resolve the company through the authenticated user's ownership association:

```ruby
@company = current_user.owned_companies.find(params[:company_id])
@dashboard = CompanyManagerDashboard.new(company: @company).call
```

Keep aggregation in a query object. `CompanyManagerDashboard` scopes applications and invitations through the company's job IDs, zero-fills a 30-day activity series, and returns summary totals, pipeline counts, response rates, and upcoming jobs. The ViewComponent receives the finished result and performs no database queries.

Make plan benefits observable:

- Studio companies display a reusable visibility badge on company and job pages.
- The manager dashboard exposes priority-support and integration-preview actions.
- Non-Studio plans do not render Studio benefit claims.

## Prevention

Whenever pricing copy changes, add a component or integration test proving that the promised capability has a discoverable product surface. Test owner and non-owner access to every company-management route, and scope analytics from the authorized company rather than loading global records and filtering afterward.
