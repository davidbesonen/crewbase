class Usr::CrewImportsController < ApplicationController
  class InvalidReview < StandardError; end
  before_action :set_company
  before_action :set_import, only: [ :show, :update ]

  def new
  end

  def template
    send_data CrewRosterTemplate.new.to_xlsx, filename: "knowshow-crew-roster.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def create
    rows = CrewRosterSpreadsheet.new(file: params[:spreadsheet]).rows
    if rows.empty?
      flash.now[:alert] = "Your spreadsheet has no crew rows yet. Add people below the header, then upload it again."
      return render :new, status: :unprocessable_entity
    end
    @company.crew_imports.where(imported_at: nil, created_at: ...24.hours.ago).delete_all
    batch = @company.crew_imports.create!(uploaded_by: current_user, rows:)
    redirect_to usr_company_crew_import_path(@company, batch)
  rescue CrewRosterSpreadsheet::InvalidFile => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_entity
  end

  def show
    return redirect_to @roster_return_path, notice: "This import is already complete." if @import.imported_at?
    return redirect_to new_usr_company_crew_import_path(@company), alert: "This review expired. Upload the spreadsheet again." if @import.expired?

    @review = CrewRosterReview.new(company: @company, rows: @import.rows)
  end

  def update
    rows = submitted_rows
    selected = rows.reject { |row| row["include"] == "0" }
    result = CrewRosterImport.new(import: @import, rows: selected).call
    if result.success?
      redirect_to @roster_return_path, notice: "Added #{@import.imported_count} crew to your private roster. No accounts or invitations were sent."
    else
      @import.update!(rows:) unless @import.imported_at?
      @review = CrewRosterReview.new(company: @company, rows:)
      flash.now[:alert] = result.error
      render :show, status: :unprocessable_entity
    end
  rescue InvalidReview
    @review = CrewRosterReview.new(company: @company, rows: @import.rows)
    flash.now[:alert] = "This review could not be submitted. Reload it and try again. Nothing was added."
    render :show, status: :unprocessable_entity
  end

  private

  def set_company
    @company = Company.roster_uploadable_by(current_user).find(params[:company_id])
    @roster_owner = @company.is_owner?(current_user)
    @roster_return_path = @roster_owner ? usr_company_crew_members_path(@company) : usr_company_path(@company)
    @roster_return_label = @roster_owner ? "Back To Roster" : "Back To Company"
    @entitlement = CompanyPlanEntitlement.new(@company)
    response.headers["Cache-Control"] = "private, no-store"
  end

  def set_import = @import = @company.crew_imports.find(params[:id])

  def submitted_rows
    # One bounded JSON form part avoids Rack's parameter-count limit for 500
    # editable people. Ordinary form rows remain supported for smaller reviews.
    rows = if params[:rows_payload].is_a?(String)
      raise InvalidReview if params[:rows_payload].bytesize > 16.megabytes
      JSON.parse(params[:rows_payload])
    else
      params.fetch(:rows, ActionController::Parameters.new).values
    end
    raise InvalidReview unless rows.is_a?(Array) && rows.size.between?(1, CrewRosterSpreadsheet::MAX_ROWS)
    rows.map do |row|
      raise InvalidReview unless row.is_a?(Hash) || row.is_a?(ActionController::Parameters)
      values = row.is_a?(ActionController::Parameters) ? row : ActionController::Parameters.new(row)
      values.permit(*CrewMember::FIELDS, :include).to_h
    end
  rescue JSON::ParserError
    raise InvalidReview
  end
end
