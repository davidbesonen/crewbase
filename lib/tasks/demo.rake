namespace :demo do
  desc "Initialize fictional demo data once; preserve edits on subsequent deploys"
  task seed: :environment do
    InstallDemoMarketplace.new(enabled: ENV["CREWBASE_DEMO"] == "true",
      owner_password: ENV["DEMO_OWNER_PASSWORD"]).call
    puts "Demo marketplace is ready."
  end
end
