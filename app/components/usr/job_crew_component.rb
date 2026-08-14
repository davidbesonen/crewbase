module Usr
  class JobCrewComponent < ApplicationComponent
    def initialize(job:, positions:, candidates:, schedule_rows:)
      @job = job
      @positions = positions
      @candidates = candidates
      @schedule_rows = schedule_rows
    end

    private

    attr_reader :job, :positions, :candidates, :schedule_rows

    def compensation_period_options
      CrewPosition.pay_periods.keys.map { |period| [ period.humanize, period ] }
    end

    def available_candidates(position)
      @available_candidates ||= {}
      @available_candidates[position.id] ||= begin
        assigned_ids = position.crew_assignments.map(&:profile_id)
        candidates.reject { |candidate| assigned_ids.include?(candidate.profile.id) }
      end
    end

    def replacement_candidates(assignment)
      other_assigned_ids = assignment.crew_position.crew_assignments
        .reject { |existing| existing.id == assignment.id }
        .map(&:profile_id)

      candidates.reject do |candidate|
        candidate.profile.id == assignment.profile_id || other_assigned_ids.include?(candidate.profile.id)
      end
    end

    def assignment_modal_id(position)
      "assign-crew-position-#{position.id}"
    end

    def replacement_modal_id(assignment)
      "replace-crew-assignment-#{assignment.id}"
    end
  end
end
