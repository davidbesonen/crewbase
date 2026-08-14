class ChangeLogEntriesController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @change_log_entries = ChangeLogEntry.published
    @marketing_page = true
    @page_title = "What's new | Crewbase"
  end
end
