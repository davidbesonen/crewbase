namespace :venues do
  desc "Import or refresh KnowShow's bundled public U.S. venue catalog"
  task import: :environment do
    puts "Imported #{ImportVenueCatalog.new.call} public venues. Company venue notes are preserved."
  end
end
