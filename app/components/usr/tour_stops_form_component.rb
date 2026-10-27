class Usr::TourStopsFormComponent < ApplicationComponent
  Row = Data.define(:index, :values) do
    def name(key) = "stops[#{index}][#{key}]"
    def id(key) = "stop_#{index}_#{key}"
  end

  def initialize(project:, jobs:, templates:, venues:, stops:)
    @project, @jobs, @templates, @venues = project, jobs, templates, venues
    @rows = stops.each_with_index.map { |values, index| Row.new(index:, values:) }
  end

  def setup_options
    @templates.map { |template| [ "Template: #{template.name}", "template:#{template.id}" ] } + @jobs.map { |job| [ "Gig: #{job.title}", "job:#{job.id}" ] }
  end

  def setups? = @templates.any? || @jobs.any?
  def heading = @project.multi_show? ? "Add Multiple Shows" : "Create Tour Stops"
  def add_row_label = @project.multi_show? ? "Add Another Show" : "Add Another Stop"
  def create_label = @project.multi_show? ? "Create Draft Shows" : "Create Draft Tour Stops"
  def remove_label = @project.multi_show? ? "Remove Show" : "Remove Stop"
end
