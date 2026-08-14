# frozen_string_literal: true

require Rails.root.join("app", "forms", "bootstrap_form_builder")

ActiveSupport.on_load(:action_view) do
  ActionView::Base.default_form_builder = BootstrapFormBuilder
end
