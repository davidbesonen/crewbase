namespace :venues do
  desc "Import or refresh KnowShow's bundled public U.S. venue catalog"
  task import: :environment do
    puts "Prepared #{ImportVenueCatalog.new.call(force: ENV['FORCE'] == 'true')} public venues. Company venue notes are preserved."
  end
end
