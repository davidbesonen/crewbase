class Usr::Network::ShareFormComponent < ApplicationComponent
  def initialize(job:, share:, recipients:)
    @job, @share, @recipients = job, share, recipients
  end

  private

  attr_reader :job, :share, :recipients
end
