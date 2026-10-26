# Specific occupations remain the maintained matching catalog.
module OccupationsV2
  BY_INDUSTRY = {
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
    }.freeze

  def self.install!
    model = Class.new(ActiveRecord::Base) { self.table_name = "occupations" }
    BY_INDUSTRY.values.flatten.uniq.each { |name| model.find_or_create_by!(name: name, category_key: nil) }
  end
end
