class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Get a sorted list of all the columns in this Classes' associated table.
  # Automatically removes assumed columns created_at, updated_at, and id
  #
  # == Returns:
  # A List of Strings
  #
  def self.cols
    (self.column_names.map(&:to_sym) - [ :id, :created_at, :updated_at ]).sort
  end
end
