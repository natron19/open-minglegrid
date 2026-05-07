require "rails_helper"

RSpec.describe "Charters", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:group) { create(:support_group, user: user) }
  let(:valid_response) { File.read(Rails.root.join("spec/fixtures/files/sample_grief_circle_response.json")) }

  describe "POST /support_groups/:id/charter (create)" do
    context "as the owner" do
      before { sign_in_as(user) }

      context "with stubbed successful Gemini response" do
        before { gemini_returns(valid_response) }

        it "calls GeminiService.generate with template 'minglegrid_charter_v1'" do
          expect(GeminiService).to receive(:generate)
            .with(hash_including(template: "minglegrid_charter_v1"))
            .and_return(valid_response)
          post support_group_charter_path(group)
        end

        it "calls GeminiService.generate with all five expected variable keys" do
          expect(GeminiService).to receive(:generate)
            .with(hash_including(variables: hash_including(:purpose, :target_demographics, :meeting_cadence, :session_length_minutes, :organization_type)))
            .and_return(valid_response)
          post support_group_charter_path(group)
        end

        it "creates one GroupCharter record" do
          expect { post support_group_charter_path(group) }.to change(GroupCharter, :count).by(1)
        end

        it "creates exactly four LaunchSession records" do
          expect { post support_group_charter_path(group) }.to change(LaunchSession, :count).by(4)
        end

        it "redirects to support_group_path with success flash" do
          post support_group_charter_path(group)
          expect(response).to redirect_to(support_group_path(group))
          follow_redirect!
          expect(response.body).to include("Charter generated")
        end
      end

      context "with stubbed GeminiService::TimeoutError" do
        before { gemini_raises(GeminiService::TimeoutError) }

        it "renders a Turbo Stream response targeting 'charter-region'" do
          post support_group_charter_path(group),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("charter-region")
        end

        it "does not create any GroupCharter records" do
          expect { post support_group_charter_path(group) }.not_to change(GroupCharter, :count)
        end

        it "does not create any LaunchSession records" do
          expect { post support_group_charter_path(group) }.not_to change(LaunchSession, :count)
        end

        it "response includes a retry message" do
          post support_group_charter_path(group),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.body).to include("retry")
        end
      end

      context "with stubbed GeminiService::BudgetExceededError" do
        before { gemini_raises(GeminiService::BudgetExceededError) }

        it "renders the budget-exceeded message" do
          post support_group_charter_path(group),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.body).to include("Daily AI limit")
        end

        it "does not create records" do
          expect { post support_group_charter_path(group) }.not_to change(GroupCharter, :count)
        end
      end

      context "with stubbed GeminiService::GatekeeperError" do
        before { gemini_raises(GeminiService::GatekeeperError) }

        it "renders the gatekeeper message" do
          post support_group_charter_path(group),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.body).to include("safety check")
        end

        it "does not create records" do
          expect { post support_group_charter_path(group) }.not_to change(GroupCharter, :count)
        end
      end
    end

    context "as a different user" do
      before { sign_in_as(other) }

      it "returns 404 when a different user tries to trigger generation" do
        post support_group_charter_path(group)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        post support_group_charter_path(group)
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "POST /support_groups/:id/charter/regenerate" do
    before { sign_in_as(user) }
    before { gemini_returns(valid_response) }

    let!(:existing_charter) { create(:group_charter, :with_sessions, support_group: group) }

    context "with regenerate_sessions checked" do
      let(:full_regen) { { regenerate_sessions: "1" } }

      it "destroys the existing charter before generating" do
        old_id = existing_charter.id
        post regenerate_support_group_charter_path(group), params: full_regen
        expect(GroupCharter.exists?(old_id)).to be(false)
      end

      it "destroys all existing LaunchSession records" do
        old_session_ids = existing_charter.launch_sessions.pluck(:id)
        post regenerate_support_group_charter_path(group), params: full_regen
        expect(LaunchSession.where(id: old_session_ids)).to be_empty
      end

      it "creates a new GroupCharter" do
        post regenerate_support_group_charter_path(group), params: full_regen
        expect(group.reload.group_charter).to be_present
      end

      it "creates exactly four new LaunchSession records" do
        post regenerate_support_group_charter_path(group), params: full_regen
        expect(group.reload.group_charter.launch_sessions.count).to eq(4)
      end

      it "redirects with 'Charter generated' notice" do
        post regenerate_support_group_charter_path(group), params: full_regen
        expect(response).to redirect_to(support_group_path(group))
        follow_redirect!
        expect(response.body).to include("Charter generated")
      end
    end

    context "without regenerate_sessions (text only)" do
      it "does not destroy the existing charter" do
        old_id = existing_charter.id
        post regenerate_support_group_charter_path(group)
        expect(GroupCharter.exists?(old_id)).to be(true)
      end

      it "preserves all existing LaunchSession records" do
        old_session_ids = existing_charter.launch_sessions.pluck(:id)
        post regenerate_support_group_charter_path(group)
        expect(LaunchSession.where(id: old_session_ids).count).to eq(4)
      end

      it "updates the charter text" do
        post regenerate_support_group_charter_path(group)
        expect(existing_charter.reload.purpose_statement).to be_present
      end

      it "redirects with sessions-preserved notice" do
        post regenerate_support_group_charter_path(group)
        expect(response).to redirect_to(support_group_path(group))
        follow_redirect!
        expect(response.body).to include("Sessions preserved")
      end
    end
  end
end
