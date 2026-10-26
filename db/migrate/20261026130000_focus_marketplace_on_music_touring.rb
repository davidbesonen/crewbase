class FocusMarketplaceOnMusicTouring < ActiveRecord::Migration[8.0]
  def up
    InstallOccupationCatalog.new.call

    # Only correct the original fictional demo's market. Never reclassify real
    # companies or overwrite names, profiles, jobs, credentials or visitor edits.
    company = Company.find_by(contact_email: "team@crewbase-demo.example")
    if company&.industries&.where(name: "Broadcast & Live Streaming")&.exists?
      company.industries = [ Industry.music_touring! ]
    end
  end

  def down
    # Catalog additions are harmless. Removing them could destroy saved choices.
  end
end
