class Handle::LogsController < ApplicationController
  before_action :ensure_admin

  def index
    respond_to do |format|
      format.html
      format.text { send_file HandleLogService.instance.filename, type: 'text/plain' }
    end
  end

  private
    def ensure_admin
      raise Hydra::AccessDenied unless current_user.admin?
    end
end
