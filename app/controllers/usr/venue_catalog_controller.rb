class Usr::VenueCatalogController < ApplicationController
  def index
    render json: { venues: VenueCatalogSearch.new(query: params[:q]).results }
  end
end
