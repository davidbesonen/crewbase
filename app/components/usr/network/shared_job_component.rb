class Usr::Network::SharedJobComponent < ApplicationComponent
  def initialize(share:, viewer:, detail: false)
    @share, @viewer, @detail = share, viewer, detail
  end

  private

  attr_reader :share, :viewer, :detail
end
