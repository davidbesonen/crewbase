class Usr::CompanyStaffingComponent < ApplicationComponent
  def initialize(company:, board:, members:)
    @company, @board, @members = company, board, members
    @rows_by_job = board.rows.group_by(&:job)
    @summary = board.summary
  end

  def metrics = { gigs: "Gigs", confirmed: "Confirmed Crew", open: "Open Positions", pending: "Awaiting Replies", conflicts: "Conflicts" }
  def date_range(job) = [ job.starts_at&.to_date&.to_fs(:long), job.ends_at&.to_date&.to_fs(:long) ].compact.uniq.join(" – ").presence || "Dates not set"
  def holds_for(row) = row.position ? row.position.crew_holds : row.job.crew_holds.select { |hold| hold.crew_position_id.nil? }
  def available_members(row) = @members.reject { |member| holds_for(row).any? { |hold| hold.crew_member_id == member.id } }.map { |member| [ "#{member.full_name}#{' · Not claimed' unless member.profile_id?}", member.id ] }
  def hold_path(row) = row.position ? usr_crew_position_crew_holds_path(row.position) : usr_job_crew_holds_path(row.job)
  def roster_field_id(row) = "roster_#{row.job.id}_#{row.position&.id || 'single'}"
  def remove_hold_path(row, hold) = row.position ? usr_crew_position_crew_hold_path(row.position, hold) : usr_job_crew_hold_path(row.job, hold)
  def pending_soon?(person) = person.offer&.pending? && person.offer.expires_at && person.offer.expires_at <= 48.hours.from_now
  def board_path(from:) = usr_company_staffing_path(@company, from:, project_id: params[:project_id], q: params[:q].presence)
  def booking_people(row) = row.people.reject { |person| person.status.start_with?("Tentative") }
  def hold_person(row, hold) = row.people.find { |person| person.status.start_with?("Tentative") && (hold.crew_member.profile_id ? person.profile&.id == hold.crew_member.profile_id : person.name == hold.crew_member.full_name) }
  def visible_holds(row) = holds_for(row).select { |hold| hold_person(row, hold) }
end
