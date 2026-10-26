module Usr
  class JobContractsController < ApplicationController
    include SecureFileDelivery

    before_action :set_job
    before_action :require_owner!, only: [ :create, :destroy ]
    before_action :set_contract, only: [ :download, :destroy ]

    def create
      contract = @job.contracts.new(contract_params.merge(uploaded_by: current_user))

      if contract.save
        redirect_to job_contracts_path, notice: "Document uploaded successfully."
      else
        redirect_to job_contracts_path, alert: contract.errors.full_messages.to_sentence
      end
    end

    def download
      deliver_file(@contract.file.blob)
    end

    def destroy
      @contract.destroy!
      redirect_to job_contracts_path, notice: "Document removed."
    end

    private

    def set_job
      @job = Job.find(params[:job_id])
      return if @job.documents_visible_to?(current_user)

      raise ActiveRecord::RecordNotFound
    end

    def require_owner!
      raise ActiveRecord::RecordNotFound unless @job.company&.is_owner?(current_user)
    end

    def set_contract
      @contract = @job.contracts.find(params[:id])
    end

    def contract_params
      params.require(:job_contract).permit(:title, :file)
    end

    def job_contracts_path
      usr_job_path(@job, anchor: "job-contracts")
    end
  end
end
