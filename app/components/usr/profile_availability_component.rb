class Usr::ProfileAvailabilityComponent < ApplicationComponent
  extend Dry::Initializer

  option :overview
  option :availability_path
end
