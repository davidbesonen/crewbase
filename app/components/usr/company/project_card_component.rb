module Usr
  module Company
    class ProjectCardComponent < ApplicationComponent
      def initialize(company:, projects:)
        @company = company
        @projects = projects
      end

      private

      attr_reader :company, :projects

      def location
        company.formatted_location.presence || "Location not added yet"
      end

      def industries
        company.industries.map(&:name).sort.to_sentence.presence || "Industry not added yet"
      end

      def recent_projects
        projects.first(3)
      end

      def dates(project)
        if project.starts_on && project.ends_on
          "#{helpers.l(project.starts_on, format: :long)} – #{helpers.l(project.ends_on, format: :long)}"
        elsif project.starts_on
          "Starts #{helpers.l(project.starts_on, format: :long)}"
        elsif project.ends_on
          "Ends #{helpers.l(project.ends_on, format: :long)}"
        end
      end
    end
  end
end
