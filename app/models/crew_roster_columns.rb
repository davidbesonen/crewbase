class CrewRosterColumns
  LABELS = {
    "first_name" => "First Name", "last_name" => "Last Name", "email" => "Email", "phone" => "Phone",
    "city" => "City", "state" => "State", "country" => "Country", "role" => "Job Title / Role",
    "department" => "Department", "years_with_company" => "Years Worked With", "years_experience" => "Years Of Experience",
    "skills_text" => "Skills / Services", "equipment_text" => "Equipment", "notes" => "Private Company Notes"
  }.freeze
  ALIASES = {
    "firstname" => "first_name", "lastname" => "last_name", "emailaddress" => "email",
    "phonenumber" => "phone", "mobile" => "phone", "mobilephone" => "phone",
    "jobtitle" => "role", "title" => "role", "jobtitlerole" => "role", "province" => "state",
    "yearsworkedwith" => "years_with_company", "yearswithcompany" => "years_with_company",
    "yearsofexperience" => "years_experience", "skillservices" => "skills_text", "skillsservices" => "skills_text",
    "skills" => "skills_text", "services" => "skills_text", "equipment" => "equipment_text",
    "equipmentsoftware" => "equipment_text", "notes" => "notes", "privatecompanynotes" => "notes"
  }.freeze

  def self.key(header)
    normalized = header.to_s.downcase.gsub(/[^a-z]/, "")
    ALIASES[normalized] || CrewMember::FIELDS.find { |field| field.delete("_") == normalized }
  end
end
