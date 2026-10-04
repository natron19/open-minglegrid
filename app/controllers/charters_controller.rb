class ChartersController < ApplicationController
  before_action :set_support_group

  rate_limit to: 10, within: 1.minute, only: [:create, :regenerate],
             with: -> { redirect_to support_group_path(@support_group), alert: "Please wait before generating again." }

  def create
    generate_charter(include_sessions: true)
  end

  def regenerate
    include_sessions = params[:regenerate_sessions] == "1"
    generate_charter(include_sessions: include_sessions)
  end

  def print
    @charter = @support_group.group_charter
    return render file: Rails.public_path.join("404.html"), status: :not_found if @charter.nil?
    render layout: "print"
  end

  private

  def set_support_group
    @support_group = current_user.support_groups.find(params[:support_group_id])
  end

  def generate_charter(include_sessions:)
    raw = GeminiService.generate(
      template: "minglegrid_charter_v1",
      variables: {
        purpose:                @support_group.purpose,
        target_demographics:    @support_group.target_demographics.presence || "not specified",
        meeting_cadence:        @support_group.meeting_cadence,
        session_length_minutes: @support_group.session_length_minutes,
        organization_type:      @support_group.organization_type.humanize.downcase
      }
    )

    data = CharterParser.new(raw).parse!
    persist_charter(data, raw, include_sessions: include_sessions)
    notice = include_sessions ? "Charter generated." : "Charter text regenerated. Sessions preserved."
    redirect_to support_group_path(@support_group), notice: notice

  rescue CharterParser::ParseError => e
    if e.refusal?
      flash_error(e.message)
    else
      flash_error("The AI response couldn't be parsed. Try regenerating.")
    end
    render_charter_error

  rescue GeminiService::CrisisError
    flash_error(AiGatekeeper::CRISIS_MESSAGE)
    render_charter_error

  rescue GeminiService::GatekeeperError
    flash_error("Your group description triggered a safety check. Try shortening it or removing copied content.")
    render_charter_error

  rescue GeminiService::BudgetExceededError
    flash_error("Daily AI limit reached. Try again tomorrow.")
    render_charter_error

  rescue GeminiService::TimeoutError
    flash_error("Gemini took too long. Click retry.")
    render_charter_error

  rescue GeminiService::GeminiError
    flash_error("Something went wrong generating your charter. Please try again.")
    render_charter_error
  end

  def persist_charter(data, raw, include_sessions:)
    ActiveRecord::Base.transaction do
      existing = GroupCharter.find_by(support_group_id: @support_group.id)
      charter = if existing
        existing.update!(charter_attributes(data, raw))
        existing
      else
        @support_group.create_group_charter!(charter_attributes(data, raw))
      end

      if include_sessions
        charter.launch_sessions.destroy_all
        data["sessions"].each do |s|
          charter.launch_sessions.create!(
            session_number:   s["session_number"],
            title:            s["title"],
            check_in_format:  s["check_in_format"],
            discussion_topic: s["discussion_topic"],
            activity:         s["activity"],
            closing_ritual:   s["closing_ritual"]
          )
        end
      end
    end
  end

  def charter_attributes(data, raw)
    {
      purpose_statement:  data["purpose_statement"],
      meeting_structure:  data["meeting_structure"],
      member_commitments: data["member_commitments"],
      agreements:         data["agreements"].to_json,
      boundary_reminders: data["boundary_reminders"].to_json,
      gemini_raw:         raw,
      generated_at:       Time.current
    }
  end

  def flash_error(message)
    flash.now[:alert] = message
  end

  def render_charter_error
    @charter  = @support_group.group_charter
    @sessions = @charter&.launch_sessions&.order(:session_number)
    respond_to do |format|
      format.turbo_stream do
        if @charter
          render turbo_stream: turbo_stream.update("charter-card",
            partial: "charters/charter_card",
            locals: { support_group: @support_group, charter: @charter, error: flash[:alert] })
        else
          render turbo_stream: turbo_stream.update("charter-region",
            partial: "charters/generate_cta",
            locals: { support_group: @support_group, error: flash[:alert] })
        end
      end
      format.html { redirect_to support_group_path(@support_group), alert: flash[:alert] }
    end
  end
end
