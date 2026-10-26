# frozen_string_literal: true

class Usr::Dashboard::HelpfulToolsComponent < ApplicationComponent
  extend Dry::Initializer

  Tool = Data.define(:label, :path, :icon, :primary)

  option :jobs_path
  option :people_path
  option :saved_jobs_path
  option :availability_path
  option :profile_path

  def tools
    [
      Tool.new(label: "Find Jobs", path: jobs_path, icon: "briefcase", primary: true),
      Tool.new(label: "Find People", path: people_path, icon: "people", primary: false),
      Tool.new(label: "Saved Jobs", path: saved_jobs_path, icon: "bookmark", primary: false),
      Tool.new(label: "Availability", path: availability_path, icon: "calendar-check", primary: false),
      Tool.new(label: "My Profile", path: profile_path, icon: "person-circle", primary: false)
    ]
  end
end
