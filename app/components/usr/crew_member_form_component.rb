class Usr::CrewMemberFormComponent < ApplicationComponent
  def initialize(company:, member:)
    @company, @member = company, member
  end

  def form_url
    @member.persisted? ? usr_company_crew_member_path(@company, @member) : usr_company_crew_members_path(@company)
  end

  def input_type(key)
    return :email_field if key == "email"
    return :telephone_field if key == "phone"
    return :number_field if key.start_with?("years_")
    :text_field
  end
end
