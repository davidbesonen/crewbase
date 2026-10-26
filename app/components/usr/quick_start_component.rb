class Usr::QuickStartComponent < ApplicationComponent
  extend Dry::Initializer
  option :intent
  option :profile
  option :post_job_path
end
