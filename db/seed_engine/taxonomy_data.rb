module SeedEngineTaxonomyData
  COMMON_SKILLS = [
    "Production Safety",
    "Crew Communication",
    "Technical Troubleshooting",
    "Production Documentation",
    "Load-In / Load-Out Workflow"
  ].freeze

  SKILLS_BY_OCCUPATION = {
    "Actor" => [ "Script Analysis", "Blocking", "Improvisation", "Voice Performance", "On-Camera Performance" ],
    "Artist Manager" => [ "Artist Development", "Contract Review", "Release Strategy", "Tour Planning", "Rights Administration" ],
    "Audio Systems Engineer" => [ "PA System Design", "System Tuning", "Smaart Measurement", "Array Prediction", "Dante Audio Networking", "Network Redundancy", "Amplifier Control" ],
    "Audio Technician" => [ "Audio Patch", "Microphone Deployment", "Digital Console Operation", "Dante Audio Networking", "Cable Testing", "Intercom Systems" ],
    "Audio Engineer" => [ "Signal Flow", "Gain Structure", "Digital Console Operation", "Dante Audio Networking", "System Measurement", "Multitrack Recording", "Microphone Technique", "Intercom Systems" ],
    "Backline Technician" => [ "Guitar Setup", "Bass Setup", "Drum Tuning", "Keyboard Programming", "MIDI Troubleshooting", "Instrument Repair" ],
    "Broadcast Engineer" => [ "SMPTE ST 2110", "SDI Signal Routing", "IP Video Networking", "Genlock and Timecode", "PTP Timing", "Video Encoding", "Broadcast Audio", "Redundant Systems" ],
    "Boom Operator" => [ "Boom Microphone Technique", "Wireless Microphone Wiring", "Set Etiquette", "Timecode Workflow", "Location Sound", "Sound Reports" ],
    "Camera Operator" => [ "Camera Operation", "Lens Selection", "Focus Pulling", "Tripod and Pedestal Operation", "Gimbal Operation", "Camera Shading", "Frame Composition" ],
    "Catalog Manager" => [ "Music Metadata", "ISRC Administration", "Rights Administration", "Digital Asset Management", "Royalty Data", "Release Delivery" ],
    "Cinematographer" => [ "Cinematography", "Exposure Control", "Lighting for Camera", "Lens Selection", "Camera Movement", "Color Science", "Shot Design" ],
    "Colorist" => [ "Color Management", "Color Grading", "HDR Finishing", "Display Calibration", "ACES Workflow", "Conform and Delivery" ],
    "Composer" => [ "Composition", "Orchestration", "Film Scoring", "Music Notation", "MIDI Programming", "Arrangement", "Songwriting" ],
    "Director" => [ "Creative Direction", "Shot Planning", "Talent Direction", "Script Breakdown", "Multi-Camera Directing", "Production Communication" ],
    "Director of Photography" => [ "Lighting Design for Camera", "Camera Package Design", "Exposure Strategy", "Lens Testing", "Color Pipeline Planning", "Crew Leadership" ],
    "Digital Imaging Technician" => [ "Color Management", "On-Set Color", "Media Offload", "Checksum Verification", "Camera Matching", "Dailies Workflow", "Data Management" ],
    "Editor" => [ "Picture Editing", "Media Management", "Proxy Workflow", "Multicam Editing", "Online Conform", "Captioning", "Delivery Specifications" ],
    "Event Producer" => [ "Event Production", "Budget Management", "Vendor Management", "Run of Show", "Client Communication", "Site Planning", "Risk Management" ],
    "FOH Engineer" => [ "Front of House Mixing", "System Tuning", "Dante Audio Networking", "Soundvision Prediction", "RF Coordination", "Virtual Soundcheck", "Show File Management", "Smaart Measurement" ],
    "First Assistant Camera" => [ "Focus Pulling", "Camera Preparation", "Lens Calibration", "Wireless Video", "Camera Reports", "Follow Focus Systems" ],
    "Gaffer" => [ "Set Lighting", "Entertainment Power Distribution", "Load Calculations", "DMX Control", "Lighting Safety", "Generator Operation" ],
    "Graphics Operator" => [ "Live Graphics Operation", "Data Integration", "Lower Thirds", "Scorebug Operation", "Key and Fill", "MOS Workflow" ],
    "Hair & Makeup Artist" => [ "Corrective Makeup", "HD Makeup", "Airbrush Makeup", "Hair Styling", "Wig Application", "Continuity Documentation", "Sanitation" ],
    "Instructor" => [ "Curriculum Design", "Technical Training", "Learning Assessment", "Classroom Facilitation", "Remote Instruction", "Accessibility" ],
    "Key Grip" => [ "Grip Equipment", "Camera Rigging", "Rigging Safety", "Dolly Operation", "Overhead Frames", "Vehicle Mounts" ],
    "LED Technician" => [ "LED Wall Assembly", "LED Processing", "Signal Distribution", "Pixel Mapping", "Color Calibration", "Video Networking", "Power Distribution" ],
    "Lighting Designer" => [ "Lighting Design", "Lighting Programming", "DMX and RDM", "sACN Networking", "Art-Net Networking", "Vectorworks Spotlight", "Photometrics", "Cueing" ],
    "Lighting Technician" => [ "Fixture Setup", "DMX Addressing", "RDM Configuration", "sACN Networking", "Power Distribution", "Lighting Console Operation", "Fixture Maintenance", "Followspot Operation" ],
    "Line Producer" => [ "Production Budgeting", "Crew Planning", "Vendor Negotiation", "Production Insurance", "Cost Reporting", "Schedule Management" ],
    "Mastering Engineer" => [ "Audio Mastering", "Loudness Standards", "Critical Listening", "Metadata and ISRC", "DDP Authoring", "Immersive Audio Mastering" ],
    "Mixing Engineer" => [ "Music Mixing", "Critical Listening", "Automation", "Vocal Production", "Mix Translation", "Immersive Audio Mixing", "Recall Documentation" ],
    "Monitor Engineer" => [ "Monitor Mixing", "IEM Mixing", "RF Coordination", "Dante Audio Networking", "Stage Patch", "Talkback Systems", "Show File Management" ],
    "Motion Graphics Designer" => [ "Motion Design", "2D Animation", "3D Animation", "Compositing", "Typography", "Rendering", "Color Management" ],
    "Music Producer" => [ "Music Production", "Arrangement", "Beat Making", "Vocal Production", "MIDI Programming", "Sound Design", "Session Direction", "Genre Production" ],
    "Musician" => [ "Sight Reading", "Chart Reading", "Improvisation", "Click Track Performance", "Playback Integration", "Music Theory", "Session Etiquette" ],
    "Podcaster" => [ "Podcast Production", "Interview Technique", "Dialogue Editing", "Remote Recording", "RSS Publishing", "Loudness Standards", "Show Research" ],
    "Post-Production Supervisor" => [ "Post Workflow Design", "Delivery Specifications", "Color Pipeline Planning", "VFX Turnover", "Audio Post Coordination", "Archive Strategy" ],
    "Playback Technician" => [ "Show Playback", "Timecode", "MIDI and OSC", "Redundant Playback", "Click and Guide Tracks", "Audio Interface Routing" ],
    "Producer" => [ "Production Planning", "Budget Management", "Creative Development", "Client Communication", "Crew Hiring", "Schedule Management", "Rights and Releases" ],
    "Production Assistant" => [ "Set Protocol", "Lockups", "Talent Support", "Radio Etiquette", "Paperwork Distribution", "Production Runs" ],
    "Production Coordinator" => [ "Call Sheets", "Travel Coordination", "Crew Onboarding", "Purchase Orders", "Release Management", "Production Reporting" ],
    "Production Designer" => [ "Production Design", "Visual Research", "Art Department Budgeting", "Set Decoration", "Drafting", "Material Sourcing" ],
    "Production Manager" => [ "Crew Scheduling", "Budget Tracking", "Labor Coordination", "Vendor Management", "Site Logistics", "Safety Planning", "Permitting" ],
    "Production Sound Mixer" => [ "Production Sound Mixing", "RF Coordination", "Timecode Workflow", "Wireless Microphones", "Location Recording", "Sound Reports" ],
    "Re-recording Mixer" => [ "Dialogue Mixing", "Sound Effects Mixing", "Surround Mixing", "Dolby Atmos Mixing", "Loudness Standards", "Printmaster Delivery" ],
    "Replay Operator" => [ "Instant Replay", "Clip Management", "Slow Motion Operation", "Highlight Building", "Shared Storage", "EVS Networking" ],
    "Reporter" => [ "Field Reporting", "Interview Technique", "Script Writing", "Live Shot Workflow", "Editorial Research", "IFB Operation" ],
    "RF Technician" => [ "RF Coordination", "Wireless Frequency Planning", "Intermodulation Analysis", "Antenna Distribution", "Spectrum Analysis", "Wireless Microphone Deployment" ],
    "Rigger" => [ "Arena Rigging", "Theatre Rigging", "Motor Systems", "Load Calculations", "Fall Protection", "Rigging Inspection", "Bridle Calculations" ],
    "Set Designer" => [ "Scenic Design", "Technical Drafting", "3D Modeling", "Model Making", "Material Specification", "Shop Drawings" ],
    "Sound Designer" => [ "Sound Design", "Dialogue Editing", "Foley", "Field Recording", "Surround Mixing", "Immersive Audio", "Audio Implementation" ],
    "Show Caller" => [ "Calling Cues", "Run of Show", "Show Flow", "Client Communication", "Rehearsal Leadership", "Intercom Etiquette" ],
    "Stage Manager" => [ "Calling Cues", "Run of Show", "Rehearsal Management", "Show Reports", "Intercom Etiquette", "Backstage Coordination", "Emergency Procedures" ],
    "Stagehand" => [ "Stagecraft", "Cable Management", "Truck Loading", "Deck Operations", "Basic Rigging", "Entertainment Power Distribution", "Forklift Spotting" ],
    "Technical Director" => [ "Technical Direction", "Rigging Systems", "Entertainment Power Distribution", "Technical Drafting", "Crew Leadership", "Safety Planning", "Production Scheduling" ],
    "Tour Manager" => [ "Tour Logistics", "Tour Accounting", "Travel Coordination", "Settlement", "Immigration and Carnets", "Day Sheet Management", "Crisis Management" ],
    "Venue Manager" => [ "Venue Operations", "Event Settlement", "Crowd Management", "Emergency Planning", "Labor Scheduling", "Hospitality Coordination", "Facility Systems" ],
    "Video Engineer" => [ "Video Signal Flow", "SDI Routing", "SMPTE ST 2110", "Colorimetry", "Genlock and Timecode", "Camera Shading", "Projection Blending", "Video Networking" ],
    "Videographer" => [ "Camera Operation", "Location Audio", "Interview Lighting", "Gimbal Operation", "Media Management", "Editing", "Color Correction" ],
    "Visual Effects Artist" => [ "Compositing", "Rotoscoping", "Keying", "Tracking", "3D Integration", "Color Management", "Render Management" ],
    "Wardrobe Stylist" => [ "Wardrobe Styling", "Costume Continuity", "Fittings", "Alterations", "Garment Care", "Shopping and Returns", "On-Set Wardrobe" ]
  }.freeze

  EQUIPMENT_BY_OCCUPATION = {
    "Actor" => { "Teleprompter" => nil, "Wireless Lavalier Systems" => nil, "IFB Systems" => nil },
    "Artist Manager" => { "Master Tour" => "Eventric", "Chartmetric" => nil, "DISCO" => nil, "Google Workspace" => "Google" },
    "Audio Systems Engineer" => { "Smaart" => "Rational Acoustics", "d&b ArrayCalc" => "d&b audiotechnik", "d&b R1" => "d&b audiotechnik", "L-Acoustics Soundvision" => "L-Acoustics", "L-Acoustics LA Network Manager" => "L-Acoustics", "Meyer Sound MAPP 3D" => "Meyer Sound" },
    "Audio Technician" => { "Yamaha CL/QL Series" => "Yamaha", "Allen & Heath SQ Series" => "Allen & Heath", "Dante Controller" => "Audinate", "Clear-Com Arcadia" => "Clear-Com", "Audio Cable Testers" => nil },
    "Audio Engineer" => { "Avid Pro Tools" => "Avid", "Dante Controller" => "Audinate", "Yamaha RIVAGE Series" => "Yamaha", "DiGiCo Quantum Series" => "DiGiCo", "Avid VENUE S6L" => "Avid", "Allen & Heath dLive" => "Allen & Heath", "Smaart" => "Rational Acoustics", "Shure Wireless Workbench" => "Shure" },
    "Backline Technician" => { "Kemper Profiler" => "Kemper", "Fractal Audio Axe-Fx" => "Fractal Audio", "Roland V-Drums" => "Roland", "Nord Stage" => "Nord", "Peterson Strobe Tuners" => "Peterson" },
    "Broadcast Engineer" => { "Ross Ultrix" => "Ross", "Evertz MAGNUM" => "Evertz", "Lawo V__matrix" => "Lawo", "Grass Valley IP Routing" => "Grass Valley", "Tektronix PRISM" => "Tektronix", "Haivision Makito" => "Haivision" },
    "Boom Operator" => { "Schoeps CMIT 5U" => "Schoeps", "Sennheiser MKH 50" => "Sennheiser", "Ambient Boompoles" => "Ambient", "Tentacle Sync" => "Tentacle Sync" },
    "Camera Operator" => { "Sony HDC-5500" => "Sony", "Sony FX9" => "Sony", "ARRI ALEXA 35" => "ARRI", "Canon C500 Mark II" => "Canon", "Sachtler Flowtech" => "Sachtler", "DJI Ronin 4D" => "DJI" },
    "Catalog Manager" => { "DISCO" => nil, "Soundmouse" => nil, "FUGA" => nil, "Synchtank" => nil },
    "Cinematographer" => { "ARRI ALEXA 35" => "ARRI", "Sony VENICE 2" => "Sony", "RED V-RAPTOR" => "RED", "Cooke S8/i Lenses" => "Cooke", "ARRI Signature Primes" => "ARRI" },
    "Colorist" => { "DaVinci Resolve Studio" => "Blackmagic Design", "DaVinci Resolve Advanced Panel" => "Blackmagic Design", "Flanders Scientific Reference Monitors" => "Flanders Scientific", "Calman" => "Portrait Displays" },
    "Composer" => { "Logic Pro" => "Apple", "Cubase Pro" => "Steinberg", "Dorico Pro" => "Steinberg", "Sibelius" => "Avid", "Native Instruments Kontakt" => "Native Instruments" },
    "Director" => { "Ross Carbonite" => "Ross", "Blackmagic ATEM Constellation" => "Blackmagic Design", "Clear-Com Eclipse HX" => "Clear-Com", "Teleprompter Systems" => nil },
    "Director of Photography" => { "ARRI ALEXA 35" => "ARRI", "Sony VENICE 2" => "Sony", "Sekonic Light Meters" => "Sekonic", "ARRI SkyPanel X" => "ARRI", "Cooke S8/i Lenses" => "Cooke" },
    "Digital Imaging Technician" => { "Pomfort Livegrade" => "Pomfort", "Pomfort Silverstack" => "Pomfort", "DaVinci Resolve Studio" => "Blackmagic Design", "Flanders Scientific Reference Monitors" => "Flanders Scientific", "Codex Media Stations" => "Codex" },
    "Editor" => { "Avid Media Composer" => "Avid", "Adobe Premiere Pro" => "Adobe", "DaVinci Resolve Studio" => "Blackmagic Design", "Final Cut Pro" => "Apple", "Frame.io" => "Adobe" },
    "Event Producer" => { "Vectorworks Spotlight" => "Vectorworks", "Event Draw" => nil, "Cvent" => nil, "Shoflo" => nil, "Microsoft 365" => "Microsoft" },
    "FOH Engineer" => { "Avid VENUE S6L" => "Avid", "DiGiCo Quantum Series" => "DiGiCo", "Yamaha RIVAGE Series" => "Yamaha", "Allen & Heath dLive" => "Allen & Heath", "Smaart" => "Rational Acoustics", "d&b R1" => "d&b audiotechnik", "L-Acoustics Soundvision" => "L-Acoustics" },
    "First Assistant Camera" => { "ARRI Hi-5" => "ARRI", "Preston FIZ" => "Preston Cinema Systems", "Teradek RT" => "Teradek", "Cine RT" => nil, "SmallHD Monitors" => "SmallHD" },
    "Gaffer" => { "ARRI SkyPanel X" => "ARRI", "Aputure Electro Storm" => "Aputure", "DMX Lighting Control" => nil, "Portable Power Distribution" => nil, "Honda Generators" => "Honda" },
    "Graphics Operator" => { "Ross XPression" => "Ross", "Chyron PRIME" => "Chyron", "Vizrt Viz Engine" => "Vizrt", "NewBlue Captivate" => "NewBlue" },
    "Hair & Makeup Artist" => { "Temptu Airbrush Systems" => "Temptu", "Portable Makeup Stations" => nil, "Wig Ventilation Tools" => nil },
    "Instructor" => { "Zoom Rooms" => "Zoom", "Microsoft Teams Rooms" => "Microsoft", "SMART Board" => "SMART", "Canvas LMS" => nil },
    "Key Grip" => { "Chapman Dollies" => "Chapman", "Fisher Dollies" => "Fisher", "Matthews Grip Equipment" => "Matthews", "Modern Studio Equipment" => "Modern Studio Equipment", "Dana Dolly" => "Dana Dolly" },
    "LED Technician" => { "Brompton Tessera" => "Brompton Technology", "NovaStar MX Series" => "NovaStar", "ROE Visual LED Panels" => "ROE Visual", "Megapixel HELIOS" => "Megapixel", "disguise" => "disguise" },
    "Lighting Designer" => { "grandMA3" => "MA Lighting", "ETC Eos Family" => "ETC", "ChamSys MagicQ" => "ChamSys", "Hog 4" => "High End Systems", "Vectorworks Spotlight" => "Vectorworks", "Capture" => nil, "WYSIWYG" => "CAST" },
    "Lighting Technician" => { "grandMA3" => "MA Lighting", "ETC Eos Family" => "ETC", "Swisson XMT Series" => "Swisson", "City Theatrical DMXcat" => "City Theatrical", "Luminex GigaCore" => "Luminex" },
    "Line Producer" => { "Movie Magic Budgeting" => "Entertainment Partners", "Movie Magic Scheduling" => "Entertainment Partners", "Scenechronize" => "Entertainment Partners", "Wrapbook" => nil },
    "Mastering Engineer" => { "Sequoia" => "MAGIX", "Pyramix" => "Merging Technologies", "iZotope RX" => "iZotope", "NUGEN Audio VisLM" => "NUGEN Audio", "DDP Creator" => nil },
    "Mixing Engineer" => { "Avid Pro Tools" => "Avid", "Logic Pro" => "Apple", "Solid State Logic AWS" => "Solid State Logic", "Neve 88RS" => "AMS Neve", "Dolby Atmos Renderer" => "Dolby" },
    "Monitor Engineer" => { "DiGiCo Quantum Series" => "DiGiCo", "Yamaha RIVAGE Series" => "Yamaha", "Allen & Heath dLive" => "Allen & Heath", "Shure Wireless Workbench" => "Shure", "Wisycom Manager" => "Wisycom", "Dante Controller" => "Audinate" },
    "Motion Graphics Designer" => { "Adobe After Effects" => "Adobe", "Cinema 4D" => "Maxon", "Blender" => nil, "Unreal Engine" => "Epic Games", "Adobe Illustrator" => "Adobe" },
    "Music Producer" => { "Avid Pro Tools" => "Avid", "Logic Pro" => "Apple", "Ableton Live" => "Ableton", "FL Studio" => "Image-Line", "Native Instruments Maschine" => "Native Instruments", "Akai MPC" => "Akai" },
    "Musician" => { "MainStage" => "Apple", "Ableton Live" => "Ableton", "Kemper Profiler" => "Kemper", "Fractal Audio Axe-Fx" => "Fractal Audio", "Nord Stage" => "Nord", "Roland V-Drums" => "Roland" },
    "Podcaster" => { "RØDECaster Pro II" => "RØDE", "Shure SM7B" => "Shure", "Zoom PodTrak P8" => "Zoom", "Descript" => nil, "Riverside" => nil },
    "Post-Production Supervisor" => { "ShotGrid" => "Autodesk", "Frame.io" => "Adobe", "Avid Media Composer" => "Avid", "DaVinci Resolve Studio" => "Blackmagic Design", "Signiant Media Shuttle" => "Signiant" },
    "Playback Technician" => { "Ableton Live" => "Ableton", "Qlab" => "Figure 53", "MOTU Audio Interfaces" => "MOTU", "iConnectivity PlayAUDIO" => "iConnectivity", "Radial SW8" => "Radial Engineering" },
    "Producer" => { "Movie Magic Budgeting" => "Entertainment Partners", "StudioBinder" => nil, "Frame.io" => "Adobe", "Google Workspace" => "Google" },
    "Production Assistant" => { "Two-Way Radios" => nil, "Set Lighting Walkie Accessories" => nil, "Production Paperwork Kits" => nil },
    "Production Coordinator" => { "Scenechronize" => "Entertainment Partners", "StudioBinder" => nil, "Wrapbook" => nil, "Google Workspace" => "Google" },
    "Production Designer" => { "Vectorworks" => "Vectorworks", "SketchUp Pro" => "Trimble", "AutoCAD" => "Autodesk", "Adobe Creative Cloud" => "Adobe", "Wacom Cintiq" => "Wacom" },
    "Production Manager" => { "Vectorworks Spotlight" => "Vectorworks", "Shoflo" => nil, "R2" => nil, "Master Tour" => "Eventric", "Motorola MOTOTRBO" => "Motorola" },
    "Production Sound Mixer" => { "Sound Devices 8-Series" => "Sound Devices", "Zaxcom Nova" => "Zaxcom", "Shure Axient Digital" => "Shure", "Wisycom Wireless Systems" => "Wisycom", "Tentacle Sync" => "Tentacle Sync" },
    "Re-recording Mixer" => { "Avid Pro Tools" => "Avid", "Avid S6" => "Avid", "Dolby Atmos Renderer" => "Dolby", "NUGEN Audio VisLM" => "NUGEN Audio" },
    "Replay Operator" => { "EVS XT-VIA" => "EVS", "EVS LSM-VIA" => "EVS", "Grass Valley LiveTouch" => "Grass Valley", "Ross Mira" => "Ross" },
    "Reporter" => { "LiveU LU800" => "LiveU", "Dejero EnGo" => "Dejero", "Sony PXW-Z190" => "Sony", "IFB Systems" => nil },
    "RF Technician" => { "Shure Wireless Workbench" => "Shure", "Wisycom Manager" => "Wisycom", "Sennheiser Wireless Systems Manager" => "Sennheiser", "RF Explorer" => nil, "TinySA Ultra" => nil, "Shure Axient Digital" => "Shure" },
    "Rigger" => { "CM Lodestar Hoists" => "Columbus McKinnon", "Stagemaker Hoists" => "Stagemaker", "BroadWeigh Load Cells" => "BroadWeigh", "Chain Hoist Controllers" => nil, "Fall Protection Systems" => nil },
    "Set Designer" => { "Vectorworks" => "Vectorworks", "AutoCAD" => "Autodesk", "SketchUp Pro" => "Trimble", "Rhino 3D" => "McNeel", "Revit" => "Autodesk" },
    "Sound Designer" => { "Avid Pro Tools" => "Avid", "iZotope RX" => "iZotope", "Soundminer" => nil, "QLab" => "Figure 53", "Dolby Atmos Renderer" => "Dolby" },
    "Show Caller" => { "Shoflo" => nil, "CuePilot" => nil, "Clear-Com Arcadia" => "Clear-Com", "Riedel Artist" => "Riedel" },
    "Stage Manager" => { "Clear-Com Arcadia" => "Clear-Com", "Riedel Artist" => "Riedel", "QLab" => "Figure 53", "Shoflo" => nil, "Two-Way Radios" => nil },
    "Stagehand" => { "CM Lodestar Hoists" => "Columbus McKinnon", "Genie Material Lifts" => "Genie", "Motorola MOTOTRBO" => "Motorola", "Cable Ramps" => nil, "Chain Hoist Controllers" => nil },
    "Technical Director" => { "Vectorworks Spotlight" => "Vectorworks", "AutoCAD" => "Autodesk", "grandMA3" => "MA Lighting", "ETC Eos Family" => "ETC", "Chain Hoist Controllers" => nil },
    "Tour Manager" => { "Master Tour" => "Eventric", "Eventric Live Access" => "Eventric", "Google Workspace" => "Google", "QuickBooks Online" => "Intuit" },
    "Venue Manager" => { "Momentus" => nil, "Ungerboeck" => nil, "Motorola MOTOTRBO" => "Motorola", "Access Control Systems" => nil },
    "Video Engineer" => { "Barco E2" => "Barco", "Analog Way Aquilon" => "Analog Way", "Ross Carbonite" => "Ross", "Blackmagic Videohub" => "Blackmagic Design", "AJA FS-HDR" => "AJA", "Evertz EQX" => "Evertz" },
    "Videographer" => { "Sony FX6" => "Sony", "Canon C70" => "Canon", "DJI Ronin RS 4 Pro" => "DJI", "Adobe Premiere Pro" => "Adobe", "DaVinci Resolve Studio" => "Blackmagic Design" },
    "Visual Effects Artist" => { "Foundry Nuke" => "Foundry", "Autodesk Flame" => "Autodesk", "Houdini" => "SideFX", "Maya" => "Autodesk", "Unreal Engine" => "Epic Games" },
    "Wardrobe Stylist" => { "Jiffy Garment Steamers" => "Jiffy", "Industrial Sewing Machines" => nil, "Portable Wardrobe Racks" => nil, "Costume Continuity Software" => nil }
  }.freeze

  def create_skills
    IndustryAssignment.where(assignable_type: "Skill").destroy_all
    OccupationAssignment.where(assignable_type: "Skill").destroy_all
    Skill.destroy_all

    Occupation.includes(:industries).find_each do |occupation|
      skill_names = COMMON_SKILLS + SKILLS_BY_OCCUPATION.fetch(occupation.name)
      skill_names.uniq.each do |skill_name|
        skill = Skill.find_or_create_by!(name: skill_name)
        skill.occupation_assignments.find_or_create_by!(occupation:)
        occupation.industries.each { |industry| skill.industry_assignments.find_or_create_by!(industry:) }
      end
    end
  end

  def create_equipment
    IndustryAssignment.where(assignable_type: "Equipment").destroy_all
    OccupationAssignment.where(assignable_type: "Equipment").destroy_all
    Equipment.destroy_all

    Occupation.includes(:industries).find_each do |occupation|
      EQUIPMENT_BY_OCCUPATION.fetch(occupation.name).each do |equipment_name, brand_name|
        brand = Brand.find_or_create_by!(name: brand_name) if brand_name.present?
        equipment = Equipment.find_or_create_by!(name: equipment_name, brand:)
        equipment.occupation_assignments.find_or_create_by!(occupation:)
        occupation.industries.each { |industry| equipment.industry_assignments.find_or_create_by!(industry:) }
      end
    end
  end
end
