class SupportGroupsController < ApplicationController
  before_action :set_support_group, only: [:show, :edit, :update, :destroy]

  def index
    @support_groups = current_user.support_groups.order(updated_at: :desc)
  end

  def new
    @support_group = current_user.support_groups.build
  end

  def create
    @support_group = current_user.support_groups.build(support_group_params)
    if @support_group.save
      redirect_to @support_group, notice: "Group created. Generate your charter below."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @charter  = @support_group.group_charter
    @sessions = @charter&.launch_sessions&.order(:session_number)
  end

  def edit; end

  def update
    if @support_group.update(support_group_params)
      redirect_to @support_group, notice: "Group updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @support_group.destroy
    redirect_to support_groups_path, notice: "Group deleted."
  end

  private

  def set_support_group
    @support_group = current_user.support_groups.find(params[:id])
  end

  def support_group_params
    params.require(:support_group).permit(
      :name, :purpose, :target_demographics,
      :meeting_cadence, :session_length_minutes, :organization_type
    )
  end
end
