require_relative "seed_engine/mock_data"
require_relative "seed_engine/taxonomy_data"

class SeedEngine
  prepend SeedEngineTaxonomyData
  include SeedEngineMockData

  GMAIL_OWNER = {
    first_name: "David",
    last_name: "Besonen",
    email: "david.besonen139@gmail.com",
    provider: "google_oauth2",
    uid: "117627202751255199802"
  }.freeze

  def create_gmail_owner
    user = User.find_or_initialize_by(email: GMAIL_OWNER.fetch(:email))
    user.assign_attributes(GMAIL_OWNER)
    user.password = Devise.friendly_token.first(20) if user.encrypted_password.blank?
    user.save!

    %w[user app_owner].each do |role_name|
      user.assignments.find_or_create_by!(role: Role.find_by!(name: role_name))
    end
    user.profiles.find_or_create_by!(profile_type: "user")
    user
  end

  def create_industries
    Industry.destroy_all
    industries = [
      "Broadcast & Live Streaming",
      "Corporate & Special Events",
      "Education & Training",
      "Film, TV & Commercial Production",
      "Live Music & Touring",
      "Music Recording & Production",
      "Theater & Performing Arts",
      "Post-Production & Creative Services"
    ]

    industries.each do |industry_name|
      Industry.find_or_create_by(name: industry_name)
    end
  end

  def create_occupations
    IndustryAssignment.where(assignable_type: "Occupation").destroy_all
    Occupation.destroy_all
    occupations_hash = {
      "Broadcast & Live Streaming" => [
        "Audio Engineer",
        "Broadcast Engineer",
        "Camera Operator",
        "Director",
        "Graphics Operator",
        "Lighting Technician",
        "Podcaster",
        "Producer",
        "Replay Operator",
        "Reporter",
        "Technical Director",
        "Video Engineer",
        "Videographer"
      ],
      "Corporate & Special Events" => [
        "Audio Technician",
        "Event Producer",
        "LED Technician",
        "Lighting Designer",
        "Production Manager",
        "Rigger",
        "Show Caller",
        "Stage Manager",
        "Stagehand",
        "Tour Manager",
        "Video Engineer",
        "Venue Manager"
      ],
      "Education & Training" => [
        "Instructor"
      ],
      "Film, TV & Commercial Production" => [
        "Boom Operator",
        "Camera Operator",
        "Cinematographer",
        "Digital Imaging Technician",
        "Director",
        "Director of Photography",
        "First Assistant Camera",
        "Gaffer",
        "Hair & Makeup Artist",
        "Key Grip",
        "Line Producer",
        "Producer",
        "Production Assistant",
        "Production Coordinator",
        "Production Designer",
        "Production Manager",
        "Production Sound Mixer",
        "Set Designer",
        "Wardrobe Stylist"
      ],
      "Live Music & Touring" => [
        "Audio Systems Engineer",
        "Backline Technician",
        "FOH Engineer",
        "Lighting Designer",
        "Lighting Technician",
        "Monitor Engineer",
        "Musician",
        "Playback Technician",
        "RF Technician",
        "Rigger",
        "Stagehand",
        "Tour Manager",
        "Video Engineer"
      ],
      "Music Recording & Production" => [
        "Artist Manager",
        "Audio Engineer",
        "Catalog Manager",
        "Composer",
        "Mastering Engineer",
        "Musician",
        "Mixing Engineer",
        "Music Producer",
        "Post-Production Supervisor"
      ],
      "Theater & Performing Arts" => [
        "Audio Engineer",
        "Actor",
        "Hair & Makeup Artist",
        "Lighting Designer",
        "Rigger",
        "Set Designer",
        "Stage Manager",
        "Technical Director"
      ],
      "Post-Production & Creative Services" => [
        "Colorist",
        "Editor",
        "Motion Graphics Designer",
        "Re-recording Mixer",
        "Sound Designer",
        "Visual Effects Artist"
      ]
    }

    occupations_hash.each do |industry_name, occupation_names|
      industry = Industry.find_by(name: industry_name)
      next unless industry

      occupation_names.each do |occupation_name|
        occupation = Occupation.find_or_create_by(name: occupation_name)
        occupation.industry_assignments.find_or_create_by!(industry: industry)
      end
    end
  end

  def create_brands
    Brand.destroy_all
    brand_names = [
      "Yamaha",
      "Shure",
      "Sennheiser",
      "Sony",
      "Canon",
      "Nikon",
      "Panasonic",
      "Avid",
      "Adobe",
      "Blackmagic Design",
      "JBL",
      "AKG",
      "Behringer",
      "Roland",
      "Fender",
      "Gibson",
      "Pearl",
      "DW Drums",
      "Electro-Voice",
      "Mackie"
    ]

    brand_names.each do |brand_name|
      Brand.find_or_create_by(name: brand_name)
    end
  end

  def create_equipment
    Equipment.destroy_all
    industry_occupations_with_equipment = {
      "Broadcast & Live Streaming" => {
        "Audio Engineer" => {
          "Yamaha CL5 Console" => "Yamaha",
          "Shure SM7B Microphone" => "Shure",
          "Waves SuperRack" => "Waves"
        },
        "Broadcast Engineer" => {
          "Ross Carbonite Switcher" => "Ross",
          "Lawo Audio Router" => "Lawo",
          "Telestream Wirecast" => "Telestream"
        },
        "Camera Operator" => {
          "Sony FX9" => "Sony",
          "Canon C300" => "Canon",
          "Sachtler Flowtech Tripod" => "Sachtler"
        },
        "Director" => {
          "Blackmagic ATEM Panel" => "Blackmagic",
          "Clear-Com Intercom" => "Clear-Com",
          "Ross XPression" => "Ross"
        },
        "Lighting Technician" => {
          "MA Lighting grandMA3" => "MA Lighting",
          "ARRI Skypanel" => "ARRI",
          "Litepanels Astra" => "Litepanels"
        },
        "Podcaster" => {
          "Rodecaster Pro" => "Rode",
          "Shure SM58" => "Shure",
          "Zoom H6 Recorder" => "Zoom"
        },
        "Producer" => {
          "MacBook Pro" => "Apple",
          "Shotgun Microphone Kit" => "Sennheiser",
          "Teradek Cube Encoder" => "Teradek"
        },
        "Reporter" => {
          "ENG Mic Kit" => "Sennheiser",
          "Sony PXW-Z90" => "Sony",
          "Dejero Live Transmitter" => "Dejero"
        },
        "Videographer" => {
          "DJI Ronin-S" => "DJI",
          "Panasonic GH6" => "Panasonic",
          "Atomos Ninja V" => "Atomos"
        }
      },
      "Corporate & Special Events" => {
        "Event Producer" => {
          "Lenovo ThinkPad" => "Lenovo",
          "iPad Pro" => "Apple",
          "Neutrik Fiber System" => "Neutrik"
        },
        "Lighting Designer" => {
          "ETC Ion Console" => "ETC",
          "Clay Paky Mythos" => "Clay Paky",
          "Chamsys MQ80" => "ChamSys"
        },
        "Production Manager" => {
          "Motorola CP200 Radios" => "Motorola",
          "Show Cue Systems" => "Show Cue Systems",
          "Whirlwind Snake" => "Whirlwind"
        },
        "Stage Manager" => {
          "Clear-Com Beltpacks" => "Clear-Com",
          "Stage Timer" => nil,
          "Yamaha TF1" => "Yamaha"
        },
        "Stagehand" => {
          "Magliner Cart" => "Magliner",
          "Milwaukee Tool Kit" => "Milwaukee",
          "Liftall Rigging Straps" => "Lift-All"
        },
        "Tour Manager" => {
          "Pelican Road Case" => "Pelican",
          "Garmin GPS" => "Garmin",
          "Sennheiser IEM Pack" => "Sennheiser"
        },
        "Venue Manager" => {
          "Access Control System" => nil,
          "Bose L1 PA" => "Bose",
          "AV Room Controller" => nil
        }
      },
      "Education & Training" => {
        "Instructor" => {
          "Zoom Rooms Kit" => "Zoom",
          "Interactive Whiteboard" => "SMART",
          "Sennheiser Clip Mic" => "Sennheiser"
        }
      },
      "Film, TV & Commercial Production" => {
        "Camera Operator" => {
          "ARRI Alexa Mini" => "ARRI",
          "Tilta Shoulder Rig" => "Tilta",
          "SmallHD Monitor" => "SmallHD"
        },
        "Cinematographer" => {
          "Cooke Prime Lens Set" => "Cooke",
          "Tiffen Filters" => "Tiffen",
          "Sekonic Light Meter" => "Sekonic"
        },
        "Director" => {
          "Viewfinder Monitor" => nil,
          "Script Supervisor iPad" => "Apple",
          "IFB Comms" => "Clear-Com"
        },
        "Director of Photography" => {
          "OConnor 2575 Head" => "OConnor",
          "SkyPanel Kit" => "ARRI",
          "DMG Lumiere" => "Rosco"
        },
        "Hair & Makeup Artist" => {
          "LED Vanity Case" => nil,
          "Temptu Airbrush" => "Temptu",
          "Ben Nye Palette" => "Ben Nye"
        },
        "Line Producer" => {
          "Budgeting Software" => "Movie Magic",
          "SetWalkie" => "SetWalkie",
          "Portable Printer" => "Brother"
        },
        "Producer" => {
          "MacBook Pro" => "Apple",
          "Sony A7S III" => "Sony",
          "Zoom F8n" => "Zoom"
        },
        "Production Assistant" => {
          "PA Kit (Pens, Tape)" => nil,
          "Two-Way Radio" => "Motorola",
          "Lockup Signs" => nil
        },
        "Production Coordinator" => {
          "Google Workspace" => "Google",
          "Label Printer" => "Brother",
          "Dropbox Subscription" => "Dropbox"
        },
        "Production Designer" => {
          "Sketching Tablet" => "Wacom",
          "Sample Swatch Kit" => nil,
          "Makita Tool Set" => "Makita"
        },
        "Production Manager" => {
          "Scheduling Software" => "StudioBinder",
          "Motorola Radios" => "Motorola",
          "Pelican Case" => "Pelican"
        },
        "Set Designer" => {
          "AutoCAD License" => "Autodesk",
          "Modeling Tools" => nil,
          "Foam Cutter" => "Hot Wire"
        },
        "Wardrobe Stylist" => {
          "Rolling Rack" => nil,
          "Steamer" => "Jiffy",
          "Sewing Kit" => "Singer"
        }
      },
      "Live Music & Touring" => {
        "Backline Technician" => {
          "Kemper Profiler" => "Kemper",
          "Tour Ready Pedalboard" => "Pedaltrain",
          "Guitar Tech Bench" => "Grover"
        },
        "FOH Engineer" => {
          "Avid S6L Console" => "Avid",
          "Shure Axient Wireless" => "Shure",
          "Meyer Sound Analyzer" => "Meyer Sound"
        },
        "Lighting Designer" => {
          "MA onPC Command Wing" => "MA Lighting",
          "Elation Proteus" => "Elation",
          "City Theatrical DMX Tools" => "City Theatrical"
        },
        "Lighting Technician" => {
          "Lift Safety Harness" => "3M",
          "Leatherman Wave" => "Leatherman",
          "Cable Tester" => "Behringer"
        },
        "Monitor Engineer" => {
          "DiGiCo SD12" => "DiGiCo",
          "Ultimate Ears IEMs" => "Ultimate Ears",
          "RF Venue Distribution" => "RF Venue"
        },
        "Musician" => {
          "Fender Stratocaster" => "Fender",
          "Gibson Les Paul" => "Gibson",
          "Yamaha Grand Piano" => "Yamaha",
          "DW Drum Kit" => "DW",
          "Roland Fantom" => "Roland",
          "Moog Sub 37" => "Moog",
          "Nord Stage 3" => "Nord",
          "Selmer Saxophone" => "Selmer",
          "Bach Trumpet" => "Bach",
          "Yamaha Violin" => "Yamaha",
          "Shure SM58" => "Shure"
        },
        "Tour Manager" => {
          "Road Case Office" => "Pelican",
          "Tour Accounting Software" => "Master Tour",
          "Travel Wi-Fi Hotspot" => "Skyroam"
        }
      },
      "Music Recording & Production" => {
        "Artist Manager" => {
          "CRM Platform" => "HubSpot",
          "MacBook Pro" => "Apple",
          "Portable Scanner" => "Fujitsu"
        },
        "Audio Engineer" => {
          "Neumann U87 Microphone" => "Neumann",
          "API 512c Preamp" => "API",
          "Avid Pro Tools HDX" => "Avid"
        },
        "Catalog Manager" => {
          "Digital Asset Manager" => "Iconik",
          "Barcode Scanner" => "Zebra",
          "External RAID Storage" => "G-Technology"
        },
        "Composer" => {
          "Native Instruments Komplete" => "Native Instruments",
          "Spitfire Orchestra" => "Spitfire Audio",
          "Vienna Symphonic Library" => "Vienna"
        },
        "Mastering Engineer" => {
          "Manley Massive Passive" => "Manley",
          "Shadow Hills Compressor" => "Shadow Hills",
          "Barefoot Monitors" => "Barefoot"
        },
        "Mixing Engineer" => {
          "SSL Fusion" => "SSL",
          "Yamaha NS-10" => "Yamaha",
          "Universal Audio Apollo" => "Universal Audio"
        },
        "Musician" => {
          "Fender Stratocaster" => "Fender",
          "Gibson Les Paul" => "Gibson",
          "Yamaha Grand Piano" => "Yamaha",
          "DW Drum Kit" => "DW",
          "Roland Fantom" => "Roland",
          "Moog Sub 37" => "Moog",
          "Nord Stage 3" => "Nord",
          "Selmer Saxophone" => "Selmer",
          "Bach Trumpet" => "Bach",
          "Yamaha Violin" => "Yamaha",
          "Shure SM7B" => "Shure"
        },
        "Music Producer" => {
          "Akai MPC" => "Akai",
          "Ableton Push" => "Ableton",
          "Genelec Monitors" => "Genelec",
          "Novation Launchkey" => "Novation",
          "UAD Satellite" => "Universal Audio"
        },
        "Post-Production Supervisor" => {
          "DaVinci Resolve Studio" => "Blackmagic",
          "Avid Shared Storage" => "Avid",
          "HP Z8 Workstation" => "HP"
        }
      },
      "Theater & Performing Arts" => {
        "Actor" => {
          "Wireless Lavalier Kit" => "Sennheiser",
          "Rehearsal iPad" => "Apple",
          "Voice Recorder" => "Zoom"
        },
        "Hair & Makeup Artist" => {
          "Portable Makeup Station" => nil,
          "Ring Light" => "Neewer",
          "Airbrush Kit" => "Temptu"
        },
        "Lighting Designer" => {
          "ETC Nomad" => "ETC",
          "Rosco Gobo Kit" => "Rosco",
          "DMX Tester" => "Doug Fleenor"
        },
        "Set Designer" => {
          "3D Printer" => "Prusa",
          "CNC Router" => "ShopBot",
          "Drafting Table" => nil
        },
        "Stage Manager" => {
          "Prompt Book Kit" => nil,
          "Q2Q Comm System" => "Clear-Com",
          "Cue Light Controller" => "Gantom"
        },
        "Technical Director" => {
          "Milwaukee Tool Pack" => "Milwaukee",
          "Rigging Hardware" => "CM",
          "Laser Measure" => "Bosch"
        }
      },
      "Post-Production & Creative Services" => {
        "Colorist" => {
          "DaVinci Resolve Panel" => "Blackmagic",
          "Flanders Scientific Monitor" => "Flanders Scientific",
          "CalMAN Calibration Kit" => "Portrait Displays"
        },
        "Editor" => {
          "Avid Media Composer" => "Avid",
          "Loupedeck Console" => "Loupedeck",
          "Thunderbolt RAID" => "Promise"
        },
        "Motion Graphics Designer" => {
          "Maxon Cinema 4D" => "Maxon",
          "Wacom Cintiq" => "Wacom",
          "Red Giant Suite" => "Red Giant"
        },
        "Sound Designer" => {
          "Sound Devices MixPre" => "Sound Devices",
          "Foley Pit" => nil,
          "Genelec 8341" => "Genelec"
        },
        "Visual Effects Artist" => {
          "Autodesk Flame" => "Autodesk",
          "Foundry Nuke" => "Foundry",
          "HP Reverb VR Kit" => "HP"
        }
      }
    }

    industry_occupations_with_equipment.each do |industry_name, occupation_equipment|
      industry = Industry.find_by(name: industry_name)
      next unless industry

      occupation_equipment.each do |occupation_name, equipment_map|
        occupation = Occupation.find_by(name: occupation_name)
        equipment_map.each do |equipment_name, brand_name|
          next if equipment_name.blank?

          brand = Brand.find_by(name: brand_name) if brand_name.present?

          equipment = Equipment.find_or_initialize_by(
            name: equipment_name,
            brand: brand
          )
          equipment.save! if equipment.new_record? || equipment.changed?

          equipment.industry_assignments.find_or_create_by!(industry: industry)
          equipment.occupation_assignments.find_or_create_by!(occupation: occupation) if occupation.present?
        end
      end
    end
  end

  def create_skills
    IndustryAssignment.where(assignable_type: "Skill").destroy_all
    Skill.destroy_all
    industry_occupations_with_skills = {
      "Broadcast & Live Streaming" => {
        "Audio Engineer" => [],
        "Broadcast Engineer" => [],
        "Camera Operator" => [],
        "Director" => [],
        "Lighting Technician" => [],
        "Podcaster" => [],
        "Producer" => [],
        "Reporter" => [],
        "Videographer" => []
      },
      "Corporate & Special Events" => {
        "Event Producer" => [],
        "Lighting Designer" => [],
        "Production Manager" => [],
        "Stage Manager" => [],
        "Stagehand" => [],
        "Tour Manager" => [],
        "Venue Manager" => []
      },
      "Education & Training" => {
        "Instructor" => []
      },
      "Film, TV & Commercial Production" => {
        "Camera Operator" => [],
        "Cinematographer" => [],
        "Director" => [],
        "Director of Photography" => [],
        "Hair & Makeup Artist" => [],
        "Line Producer" => [],
        "Producer" => [],
        "Production Assistant" => [],
        "Production Coordinator" => [],
        "Production Designer" => [],
        "Production Manager" => [],
        "Set Designer" => [],
        "Wardrobe Stylist" => []
      },
      "Live Music & Touring" => {
        "Backline Technician" => [],
        "FOH Engineer" => [],
        "Lighting Designer" => [],
        "Lighting Technician" => [],
        "Monitor Engineer" => [],
        "Musician" => [
          "Electric Guitar",
          "Acoustic Guitar",
          "Bass Guitar",
          "Drum Kit",
          "Percussion",
          "Piano / Keys",
          "Synthesizer",
          "Violin",
          "Cello",
          "Trumpet",
          "Saxophone",
          "Trombone",
          "Flute",
          "Clarinet",
          "Vocalist"
        ],
        "Tour Manager" => []
      },
      "Music Recording & Production" => {
        "Artist Manager" => [],
        "Audio Engineer" => [],
        "Catalog Manager" => [],
        "Composer" => [
          "Film Scoring",
          "Jingles",
          "Orchestration",
          "Songwriting"
        ],
        "Mastering Engineer" => [],
        "Mixing Engineer" => [],
        "Musician" => [
          "Electric Guitar",
          "Acoustic Guitar",
          "Bass Guitar",
          "Drum Kit",
          "Percussion",
          "Piano / Keys",
          "Synthesizer",
          "Violin",
          "Cello",
          "Trumpet",
          "Saxophone",
          "Trombone",
          "Flute",
          "Clarinet",
          "Vocalist"
        ],
        "Music Producer" => [
          "Beat Making",
          "Arrangement",
          "Sound Design",
          "Country",
          "Rock",
          "Pop",
          "Hip-Hop",
          "Electronic",
          "Classical",
          "Jazz",
          "R&B",
          "Folk",
          "Metal"
        ],
        "Post-Production Supervisor" => []
      },
      "Theater & Performing Arts" => {
        "Actor" => [],
        "Hair & Makeup Artist" => [],
        "Lighting Designer" => [],
        "Set Designer" => [],
        "Stage Manager" => [],
        "Technical Director" => []
      },
      "Post-Production & Creative Services" => {
        "Colorist" => [],
        "Editor" => [],
        "Motion Graphics Designer" => [],
        "Sound Designer" => [],
        "Visual Effects Artist" => []
      }
    }

    industry_occupations_with_skills.each do |industry_name, occupation_skills|
      industry = Industry.find_by(name: industry_name)
      next unless industry

      occupation_skills.each do |occupation_name, skills|
        occupation = Occupation.find_by(name: occupation_name)

        skills.each do |skill_name|
          skill = Skill.find_or_create_by(name: skill_name)

          skill.industry_assignments.find_or_create_by!(industry: industry)
          skill.occupation_assignments.find_or_create_by!(occupation: occupation) if occupation.present?
        end
      end
    end
  end

  def create_plans
    plans = [
      {
        key: "starter",
        name: "Starter",
        description: "For small production teams hiring a few roles at a time.",
        position: 1,
        monthly_price_cents: 1900,
        annual_price_cents: 19000,
        data: {
          billing_scope: "company",
          seats_limit: 2,
          active_jobs_limit: 3,
          projects_limit: 2,
          features: [ "Full crew marketplace", "Applications, invitations, and live messaging", "Basic crew recommendations" ]
        }
      },
      {
        key: "team",
        name: "Team",
        description: "The complete staffing workflow for growing event teams.",
        position: 2,
        monthly_price_cents: 4900,
        annual_price_cents: 49000,
        data: {
          billing_scope: "company",
          seats_limit: 8,
          active_jobs_limit: 15,
          projects_limit: "unlimited",
          features: [ "Multi-position gig staffing", "Shortlists and applicant pipeline", "Availability and conflict matching", "Calendar-aware staffing", "Basic staffing analytics" ]
        }
      },
      {
        key: "studio",
        name: "Studio",
        description: "For high-volume production organizations that need more capacity and support.",
        position: 3,
        monthly_price_cents: 9900,
        annual_price_cents: 99000,
        data: {
          billing_scope: "company",
          seats_limit: 25,
          active_jobs_limit: "unlimited",
          projects_limit: "unlimited",
          features: [ "Advanced staffing analytics", "Priority support and onboarding", "Enhanced company visibility", "Early access to integrations" ]
        }
      }
    ]

    plans.each do |plan_attrs|
      plan = Plan.find_or_initialize_by(key: plan_attrs.fetch(:key))
      plan.update!(plan_attrs.merge(active: true))
    end

    Plan.where.not(key: plans.pluck(:key)).or(Plan.where(key: nil)).update_all(active: false)
  end

  def create_user_plans
    crew_pro = UserPlan.find_or_initialize_by(slug: "crew-pro")
    crew_pro.update!(
      name: "Crew Pro",
      monthly_price_cents: 599,
      annual_price_cents: 4_900,
      active: true,
      data: {
        included: [
          "Support Crewbase through its beta",
          "Keep this beta rate while the subscription remains active"
        ],
        roadmap: [
          "Application insights",
          "Detailed job-match explanations",
          "Downloadable profile and resume",
          "Advanced job alerts"
        ]
      }
    )

    UserPlan.where.not(id: crew_pro.id).update_all(active: false)
  end
end
