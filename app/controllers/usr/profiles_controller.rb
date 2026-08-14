class Usr::ProfilesController < ApplicationController
  before_action :set_profile, only: :show
  before_action :set_owned_profile, only: [
    :edit, :update, :previous_page, :next_page, :edit_calendar, :update_calendar,
    :toggle_occupation_selection, :toggle_skill_selection, :toggle_equipment_selection
  ]
  before_action :set_form_data, only: [ :edit, :update, :previous_page, :next_page ]
  before_action :ensure_location_record, only: [ :edit, :update ]
  before_action :set_show_data, only: [ :show ]

  def index
    recommendations = CrewRecommender.new(
      user: current_user,
      companies: current_user.owned_companies.distinct.order(:name).to_a,
      limit: nil
    )
    @recommendations_available = recommendations.active_jobs?
    @recommended_people = @recommendations_available && params[:recommended] == "1"
    profiles_scope = Profile.includes(:user, :occupations, :locations)
      .where(profile_type: "user")
    recommendation_profile_ids = recommendations.results.map { |result| result.profile.id } if @recommended_people
    profiles_scope = profiles_scope.where(id: recommendation_profile_ids) if @recommended_people

    search_params = params.fetch(:q, {}).permit(
      :user_first_name_or_user_last_name_cont,
      :occupations_name_eq,
      :skills_name_eq,
      :locations_city_or_locations_state_or_locations_country_cont
    ).to_h
    @name_query = search_params.delete("user_first_name_or_user_last_name_cont").to_s.strip
    if @name_query.present?
      escaped_name = ActiveRecord::Base.sanitize_sql_like(@name_query)
      profiles_scope = profiles_scope.references(:user)
        .where("concat_ws(' ', users.first_name, users.last_name) ILIKE ?", "%#{escaped_name}%")
    end

    @occupations = Occupation.order(:name)
    @skills = Skill.order(:name)
    @q = profiles_scope.ransack(search_params)
    profiles = @q.result(distinct: true)
    if @recommended_people
      profile_rank = recommendation_profile_ids.each_with_index.to_h
      ranked_profiles = profiles.to_a.sort_by { |profile| profile_rank.fetch(profile.id) }
      @pagy = Pagy.new(count: ranked_profiles.size, page: params[:page])
      @profiles = ranked_profiles.slice(@pagy.offset, @pagy.limit) || []
    else
      @pagy, @profiles = pagy(profiles.order(created_at: :desc))
    end
  end

  def show
  end

  # def new
  #   @profile = current_user.profiles.find_or_create_by(user_id: current_user.id, profile_type: "user")
  # end

  def edit
    @source = params[:source].presence
    @completed_profile_mode = completed_profile_mode?
    @current_page = params[:current_page].presence || "location_form"
  end

  def edit_calendar
    @month_start = parse_month(params[:month]) || Date.current.beginning_of_month
  end

  def update
    @source = params[:source].presence
    @completed_profile_mode = completed_profile_mode?
    @page_order = [ "location_form", "occupation_form", "skill_equipment_form", "availability_form", "online_presence_form" ]
    @current_page = params[:current_page] || "location_form"
    current_page_index = @page_order.index(@current_page) || 0
    @next_page = @page_order[current_page_index + 1]

    @profile.assign_attributes(profile_params.except(:locations_attributes))
    sync_location if @completed_profile_mode || @current_page == "location_form"

    if !@completed_profile_mode && @current_page == "online_presence_form"
      @profile.completed_at = Time.current
    end

    if @profile.save
      if @completed_profile_mode
        redirect_to usr_profile_path(@profile), notice: "Profile updated!" and return
      elsif @current_page == "online_presence_form"
        current_user.visits.create(sign_in_ip: request.remote_ip) unless current_user.visits.exists?
        redirect_to usr_dashboards_path, notice: "Profile completed!" and return
      end
    else
      render :edit, status: :unprocessable_entity and return
    end
  end

  def previous_page
    @page_order = [ "location_form", "occupation_form", "skill_equipment_form", "availability_form", "online_presence_form" ]
    @current_page = params[:current_page] || "location_form"
    current_page_index = @page_order.index(@current_page) || 0
    @previous_page = @page_order[current_page_index - 1] unless current_page_index.zero?
  end

  def next_page
    @page_order = [ "location_form", "occupation_form", "skill_equipment_form", "availability_form", "online_presence_form" ]
    @current_page = params[:current_page] || "location_form"
    current_page_index = @page_order.index(@current_page) || 0
    @next_page = @page_order[current_page_index + 1]
  end

  def toggle_occupation_selection
    @source = params[:source].presence
    @completed_profile_mode = completed_profile_mode?
    occupation = Occupation.find(params[:occupation_id])
    if @profile.occupations.include?(occupation)
      @profile.occupations.delete(occupation)
    else
      @profile.occupations << occupation
    end

    set_form_data
  end

  def toggle_skill_selection
    skill = Skill.find(params[:skill_id])

    if @profile.skills.include?(skill)
      @profile.skills.delete(skill)
    else
      @profile.skills << skill
    end

    set_form_data
  end

  def toggle_equipment_selection
    equipment = Equipment.find(params[:equipment_id])

    if @profile.equipment.include?(equipment)
      @profile.equipment.delete(equipment)
    else
      @profile.equipment << equipment
    end

    set_form_data
  end

  def update_calendar
    ical_feed_url = params.require(:profile).permit(:ical_feed_url)[:ical_feed_url]
    if @profile.update(ical_feed_url: ical_feed_url, ical_last_synced_at: nil)
      if @profile.ical_feed_url.present?
        FetchIcalFeedJob.perform_later(@profile.id)
      else
        @profile.calendar_events.ical.delete_all
        @profile.update_columns(
          ical_last_synced_at: nil,
          ical_sync_attempted_at: nil,
          ical_sync_error: nil
        )
      end
      @profile.reload
      @month_start = parse_month(params[:month]) || Date.current.beginning_of_month
    else
      @month_start = Date.current.beginning_of_month
      @ical_feed_error = nil
    end

    @calendar_events = @profile.calendar_events.where(event_type: "blockout").pluck(:to_date, :id).to_h.transform_keys { |value| value.to_date.strftime("%Y-%m-%d") }
    @current_month_start = Date.current.beginning_of_month
    @max_month_start = @current_month_start.advance(months: 12)
    @previous_month_disabled = @month_start <= @current_month_start
    @next_month_disabled = @month_start >= @max_month_start
    @month_end = @month_start.end_of_month
    @range_start = @month_start.beginning_of_week(:sunday)
    @range_end = @month_end.end_of_week(:sunday)
    @weeks = (@range_start..@range_end).to_a.in_groups_of(7)
  end

  private

  def completed_profile_mode?
    params[:source] == "completed_profile"
  end

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def set_owned_profile
    @profile = current_user.profiles.find(params[:id])
  end

  def set_form_data
    catalog = ProfileFormCatalog.new(@profile)
    @occupations = catalog.occupations
    @profile_occupations = catalog.profile_occupations
    @skills = catalog.skills
    @profile_skills = catalog.profile_skills
    @equipment = catalog.equipment
    @profile_equipment = catalog.profile_equipment
    @credits = @profile.credits.display_order.to_a
    @credit_applications_by_job_id = @profile.job_applications
      .where(job_id: @credits.filter_map(&:job_id))
      .index_by(&:job_id)
  end

  def ensure_location_record
    @profile.locations.build if @profile.locations.empty?
  end

  def set_show_data
    primary_location = @profile.locations.first
    @can_view_profile_reviews = @profile.user != current_user && current_user.owned_companies.exists?
    @availability_overview = @profile.availability_overview
    @experiences = @profile.experiences.display_order
    @credits = if @profile.show_credits? || @profile.user == current_user
      credits = @profile.credits.includes(:company, :job, :project).display_order
      credits = credits.where(visible: true) unless @profile.user == current_user
      credits.to_a
    else
      []
    end
    occupation_names = @profile.occupations.limit(3).pluck(:name)
    @profile_occupation_names = occupation_names.to_sentence
    if @can_view_profile_reviews
      @recent_reviews = @profile.received_reviews
        .includes(profile: :user)
        .order(created_at: :desc)
        .limit(3)
      @review_count = @profile.received_reviews.count
      @average_rating = @profile.received_reviews.where.not(overall_rating: nil).average(:overall_rating)
    end
    @invitable_jobs = Job
      .where(company_id: current_user.owned_companies.select(:id), is_active: true, status: :published)
      .where.not(id: @profile.job_invitations.select(:job_id))
      .includes(:company)
      .order(:title)
    @available_crew_shortlists = CrewShortlist
      .joins(company: :company_assignments)
      .where(company_assignments: { user_id: current_user.id, role: "owner" })
      .where.not(id: @profile.crew_shortlists.select(:id))
      .includes(:company)
      .order(:name)

    @profile_name = @profile.user.full_name
    @profile_headline = @profile.headline.presence || @profile.occupations.limit(2).pluck(:name).to_sentence.presence || "Crewbase Member"
    @location_text = [ primary_location&.city, primary_location&.state ].compact_blank.join(", ").presence || primary_location&.country.presence || "Location not listed"
    @about_items = [
      { icon: "bi-stars", label: "Open to roles", value: @profile_occupation_names.presence || "Add target roles" },
      { icon: "bi-geo-alt", label: "Based in", value: @location_text },
      { icon: "bi-calendar-check", label: "Availability", value: @availability_overview.fetch(:status) }
    ]
  end

  def find_location(location_attributes)
    location_attrs = first_location_attributes(location_attributes)
    return if location_attrs.blank?

    Location.find_by(
      address_line_1: location_attrs[:address_line_1] || location_attrs["address_line_1"],
      address_line_2: location_attrs[:address_line_2] || location_attrs["address_line_2"],
      city: location_attrs[:city] || location_attrs["city"],
      state: location_attrs[:state] || location_attrs["state"],
      zip_code: location_attrs[:zip_code] || location_attrs["zip_code"],
      country: location_attrs[:country] || location_attrs["country"]
    )
  end

  def sync_location
    location_attrs = first_location_attributes(profile_params[:locations_attributes])
    return if location_attrs.blank?

    normalized_attrs = normalized_location_attributes(location_attrs)

    if normalized_attrs.values.all?(&:blank?)
      @profile.location_assignments.destroy_all
      @profile.locations.reset
      return
    end

    existing_location = find_location({ "0" => normalized_attrs.stringify_keys })

    if existing_location.present?
      keep_single_location(existing_location)
    else
      location = @profile.primary_location || @profile.locations.build
      location.assign_attributes(normalized_attrs)
      remove_extra_location_assignments(location) if location.persisted?
    end
  end

  def first_location_attributes(location_attributes)
    return if location_attributes.blank?

    location_attributes["0"] || location_attributes[0]
  end

  def normalized_location_attributes(location_attrs)
    {
      address_line_1: location_attrs[:address_line_1] || location_attrs["address_line_1"],
      address_line_2: location_attrs[:address_line_2] || location_attrs["address_line_2"],
      city: location_attrs[:city] || location_attrs["city"],
      state: location_attrs[:state] || location_attrs["state"],
      zip_code: location_attrs[:zip_code] || location_attrs["zip_code"],
      country: location_attrs[:country] || location_attrs["country"]
    }
  end

  def keep_single_location(location)
    @profile.location_assignments.where.not(location_id: location.id).destroy_all
    @profile.location_assignments.find_or_create_by(location: location)
    @profile.locations.reset
  end

  def remove_extra_location_assignments(location)
    @profile.location_assignments.where.not(location_id: location.id).destroy_all
    @profile.locations.reset
  end

  def profile_params
    params.require(:profile).permit(
      :profile_type,
      :completed_at,
      :bio,
      :location_city,
      :location_state,
      :location_country,
      :availability,
      :ical_feed_url,
      :website_url,
      :linkedin_url,
      :twitter_handle,
      :instagram_handle,
      :spotify_profile_url,
      :portfolio_url,
      :show_credits,
      occupation_ids: [],
      skill_ids: [],
      equipment_ids: [],
      experiences_attributes: [ :id, :title, :company_name, :company_id, :start_month, :start_year, :end_month, :end_year, :currently_active, :summary, :_destroy ],
      locations_attributes: [ :id, :address_line_1, :address_line_2, :city, :state, :zip_code, :country ]
    )
  end

  def parse_month(value)
    return nil if value.blank?

    Date.parse(value).beginning_of_month
  rescue ArgumentError
    nil
  end
end
