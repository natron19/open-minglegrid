class LaunchSessionsController < ApplicationController
  before_action :set_session

  def update
    if params[:toggle_complete].present?
      @session.update!(completed_at: @session.completed? ? nil : Time.current)
    else
      @session.update!(session_params)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "session-#{@session.id}",
          partial: "charters/session_card",
          locals: { session: @session, support_group: @support_group }
        )
      end
      format.html { redirect_to support_group_path(@support_group) }
    end
  end

  private

  def set_session
    @support_group = current_user.support_groups.find(params[:support_group_id])
    charter = @support_group.group_charter || raise(ActiveRecord::RecordNotFound)
    @session = charter.launch_sessions.find(params[:id])
  end

  def session_params
    params.require(:launch_session).permit(:scheduled_at)
  end
end
