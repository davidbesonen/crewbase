class Admin::ChangeLogEntriesController < Admin::BaseController
  before_action :set_change_log_entry, only: [ :edit, :update, :destroy ]

  def index
    @change_log_entries = ChangeLogEntry.order(published_at: :desc, created_at: :desc)
  end

  def new
    @change_log_entry = ChangeLogEntry.new
  end

  def create
    @change_log_entry = ChangeLogEntry.new(change_log_entry_params)
    return redirect_to(admin_change_log_entries_path, notice: "Update published.") if @change_log_entry.save

    render :new, status: :unprocessable_entity
  end

  def edit; end

  def update
    return redirect_to(admin_change_log_entries_path, notice: "Update saved.") if @change_log_entry.update(change_log_entry_params)

    render :edit, status: :unprocessable_entity
  end

  def destroy
    @change_log_entry.destroy!
    redirect_to admin_change_log_entries_path, notice: "Update deleted."
  end

  private

  def set_change_log_entry
    @change_log_entry = ChangeLogEntry.find(params[:id])
  end

  def change_log_entry_params
    params.require(:change_log_entry).permit(:title, :summary, :published_at)
  end
end
