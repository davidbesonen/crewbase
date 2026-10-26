module Usr
  class JobContractsComponent < ApplicationComponent
    def initialize(job:, contracts:, owner:)
      @job = job
      @contracts = contracts
      @owner = owner
    end

    private

    attr_reader :job, :contracts, :owner

    def new_contract
      @new_contract ||= JobContract.new
    end

    def file_details(contract)
      "#{contract.file.filename} · #{helpers.number_to_human_size(contract.file.byte_size)}"
    end
  end
end
