module VenueCatalogHelper
  def venue_catalog_attribution
    safe_join([
      link_to("Venue data: Overture Maps", "https://docs.overturemaps.org/guides/places/", target: "_blank", rel: "noopener"),
      link_to("Data & Licenses", "/data/venue-catalog-notice.txt", target: "_blank", rel: "noopener")
    ], " · ")
  end
end
