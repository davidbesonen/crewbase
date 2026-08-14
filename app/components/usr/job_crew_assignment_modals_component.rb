module Usr
  class JobCrewAssignmentModalsComponent < ApplicationComponent
    def initialize(positions:, candidates:)
      @positions = positions
      @candidates = candidates
    end

    private

    attr_reader :positions, :candidates

    def available_candidates(position)
      assigned_ids = position.crew_assignments.map(&:profile_id)
      candidates.reject { |candidate| assigned_ids.include?(candidate.profile.id) }
    end

    def replacement_candidates(assignment)
      excluded_ids = assignment.crew_position.crew_assignments.map(&:profile_id)
      candidates.reject { |candidate| excluded_ids.include?(candidate.profile.id) }
    end

    def open_position?(position)
      position.crew_assignments.size < position.headcount
    end

    def assignment_modal_id(position)
      "assign-crew-position-#{position.id}"
    end

    def replacement_modal_id(assignment)
      "replace-crew-assignment-#{assignment.id}"
    end
  end
end
