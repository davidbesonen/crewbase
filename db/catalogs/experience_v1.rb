# This versioned catalog is shared by the migration and seeds. Keep keys stable;
# additions should describe transferable work, never individual brands or models.
module ExperienceV1
  # General work terms support old jobs that have no structured requirements.
  # These never infer a particular product, qualification or required category.
  ROLE_TERMS = {
    "audio" => [ "audio", "sound", "FOH", "recording", "mixing" ],
    "lighting" => [ "lighting", "gaffer" ],
    "camera" => [ "camera", "photography", "cinematography", "photographer" ],
    "video" => [ "video", "broadcast", "streaming" ],
    "production" => [ "producer", "production manager", "production coordinator", "project manager" ],
    "stage" => [ "stage manager", "stagehand", "show caller", "event operations", "venue manager" ],
    "rigging" => [ "rigger", "rigging", "staging", "grip" ],
    "creative" => [ "creative director", "art director", "scenic design", "graphic design" ],
    "post" => [ "editor", "editing", "post-production", "colorist", "animation", "visual effects" ],
    "performance" => [ "musician", "actor", "performer", "composer", "music producer" ],
    "styling" => [ "wardrobe", "makeup", "hair stylist", "costume" ],
    "fabrication" => [ "carpentry", "carpenter", "fabrication", "construction" ],
    "maintenance" => [ "installation", "maintenance", "repair" ],
    "logistics" => [ "logistics", "transport", "driver", "warehouse" ],
    "hospitality" => [ "hospitality", "catering", "guest services", "customer service" ],
    "business" => [ "administration", "finance", "sales", "marketing" ],
    "technology" => [ "networking", "software", "technical support", "IT support" ],
    "training" => [ "instructor", "teaching", "training", "coach" ],
    "safety" => [ "site safety", "security", "access control" ]
  }.freeze

  ENTRIES = {
    "occupations" => {
      "audio" => [ "Audio & sound", "Live sound, recording, mixing, sound design and audio systems" ],
      "lighting" => [ "Lighting", "Lighting design, programming, installation and operation" ],
      "camera" => [ "Camera & photography", "Camera operation, cinematography, photography and camera support" ],
      "video" => [ "Video & broadcast", "Video systems, streaming, broadcast and live switching" ],
      "production" => [ "Production & project management", "Producing, coordinating, scheduling and managing projects" ],
      "stage" => [ "Stage & event operations", "Stage management, show calling, venue operations and event support" ],
      "rigging" => [ "Rigging & staging", "Rigging, stage structures, grip and temporary installations" ],
      "creative" => [ "Creative direction & design", "Art direction, visual design, scenic design and creative development" ],
      "post" => [ "Editing & post-production", "Picture editing, color, animation, visual effects and finishing" ],
      "performance" => [ "Performance & music", "Acting, presenting, musical performance, composition and music production" ],
      "styling" => [ "Wardrobe, hair & makeup", "Costume, styling, hair, makeup and continuity" ],
      "fabrication" => [ "Construction & fabrication", "Building, fabrication, scenic construction and installation" ],
      "maintenance" => [ "Installation & maintenance", "Equipment setup, servicing, repair and field support" ],
      "logistics" => [ "Transport & logistics", "Driving, delivery, warehousing, touring and material handling" ],
      "hospitality" => [ "Hospitality & customer service", "Guest services, catering, front of house and customer support" ],
      "business" => [ "Business & administration", "Office operations, finance, sales, marketing and people coordination" ],
      "technology" => [ "Technology & systems", "IT, networking, software, system integration and technical support" ],
      "training" => [ "Education & training", "Instruction, coaching, facilitation and technical training" ],
      "safety" => [ "Safety & site support", "Site safety, security, access control and emergency coordination" ]
    },
    "skills" => {
      "planning" => [ "Planning & scheduling", "Plan work, schedules, resources and handoffs" ],
      "leadership" => [ "Team leadership", "Coordinate crews, delegate work and lead delivery" ],
      "coordination" => [ "Client & vendor coordination", "Communicate requirements and coordinate external partners" ],
      "budgeting" => [ "Budgeting & administration", "Track costs, purchasing, records and project paperwork" ],
      "setup" => [ "Setup & installation", "Prepare, assemble, install and strike work systems" ],
      "operation" => [ "Technical operation", "Operate technical systems during work or a live production" ],
      "troubleshooting" => [ "Troubleshooting & repair", "Diagnose faults, maintain equipment and restore operation" ],
      "audio" => [ "Audio production", "Capture, mix, edit and deliver sound" ],
      "lighting" => [ "Lighting design & operation", "Design, program and operate lighting" ],
      "camera" => [ "Image capture", "Compose, expose and capture still or moving images" ],
      "video" => [ "Video production & delivery", "Route, switch, stream and deliver video" ],
      "editing" => [ "Editing & finishing", "Edit media, manage color and prepare final deliverables" ],
      "design" => [ "Visual design & animation", "Create graphics, design assets, animation and effects" ],
      "performance" => [ "Performance & presentation", "Perform, present, host or work with an audience" ],
      "music" => [ "Music creation", "Compose, arrange, produce and prepare music" ],
      "styling" => [ "Styling & costume", "Create and maintain wardrobe, hair and makeup looks" ],
      "fabrication" => [ "Building & fabrication", "Build, modify and finish physical structures or objects" ],
      "rigging" => [ "Rigging & load handling", "Plan and handle suspended loads and staging systems" ],
      "power" => [ "Power & electrical systems", "Set up and operate power distribution within your qualifications" ],
      "networking" => [ "Networking & system integration", "Connect, configure and support interconnected systems" ],
      "logistics" => [ "Transport & material handling", "Move people, equipment and supplies" ],
      "service" => [ "Guest & customer service", "Support customers, guests and participants" ],
      "training" => [ "Teaching & coaching", "Explain processes, train others and facilitate learning" ],
      "safety" => [ "Safety & risk coordination", "Identify risks and coordinate safe working practices" ],
      "documentation" => [ "Documentation & quality control", "Create work records, check quality and manage assets" ]
    },
    "equipment" => {
      "audio_systems" => [ "Audio systems", "Mixing consoles, microphones, speakers and recording systems" ],
      "lighting_systems" => [ "Lighting systems", "Lighting fixtures, control consoles and lighting networks" ],
      "camera_systems" => [ "Camera systems", "Cameras, lenses, camera support and monitoring" ],
      "video_systems" => [ "Video & display systems", "Switchers, projectors, LED displays and video routing" ],
      "broadcast_systems" => [ "Broadcast & streaming systems", "Encoding, replay, live graphics and transmission" ],
      "communications" => [ "Communication & wireless systems", "Intercom, radios, wireless links and RF systems" ],
      "audio_software" => [ "Audio & music software", "Audio workstations, music production and sound editing software" ],
      "video_software" => [ "Video editing & finishing software", "Editing, color grading and media finishing tools" ],
      "design_software" => [ "Design, CAD & animation software", "Graphics, drafting, modeling, animation and visual effects tools" ],
      "project_software" => [ "Project & business software", "Scheduling, budgeting, collaboration and business tools" ],
      "network_systems" => [ "Computer & network systems", "Computers, networking, servers and storage" ],
      "rigging_systems" => [ "Rigging & staging systems", "Hoists, truss, staging and suspension hardware" ],
      "power_systems" => [ "Power & distribution systems", "Generators, distribution and electrical test equipment" ],
      "shop_tools" => [ "Hand, power & fabrication tools", "Shop tools, portable tools and fabrication equipment" ],
      "vehicles" => [ "Vehicles & material handling equipment", "Work vehicles, carts, lifts and loading equipment" ],
      "instruments" => [ "Musical instruments & backline", "Instruments, amplifiers, controllers and performance equipment" ],
      "styling_tools" => [ "Wardrobe, hair & makeup tools", "Garment care, sewing, hair and makeup equipment" ],
      "hospitality_tools" => [ "Hospitality & service equipment", "Food service, guest service and point of sale systems" ],
      "measurement" => [ "Measurement & testing tools", "Meters, analyzers, calibration and inspection tools" ]
    }
  }.freeze

  def self.install!
    ENTRIES.each do |table, entries|
      model = Class.new(ActiveRecord::Base) { self.table_name = table }
      rows = entries.map { |key, (name, description)| { category_key: key, name: name, description: description } }
      model.insert_all(rows, unique_by: :category_key)
    end
  end
end
