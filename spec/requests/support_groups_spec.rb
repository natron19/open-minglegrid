require "rails_helper"

RSpec.describe "SupportGroups", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let!(:group) { create(:support_group, user: user) }

  let(:valid_params) do
    {
      support_group: {
        name: "Tuesday Grief Circle",
        purpose: "Peer support for adults grieving a spouse or parent in their first year of loss.",
        meeting_cadence: "weekly",
        session_length_minutes: 90,
        organization_type: "faith_community"
      }
    }
  end

  let(:invalid_params) do
    { support_group: { name: "", purpose: "", meeting_cadence: "", organization_type: "" } }
  end

  describe "unauthenticated access" do
    it "GET /support_groups redirects to sign in" do
      get support_groups_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "GET /support_groups/:id redirects to sign in" do
      get support_group_path(group)
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /support_groups" do
    before { sign_in_as(user) }

    it "returns 200" do
      get support_groups_path
      expect(response).to have_http_status(:ok)
    end

    it "only shows the current user's groups" do
      other_group = create(:support_group, user: other, name: "Other User's Group")
      get support_groups_path
      expect(response.body).to include(group.name)
      expect(response.body).not_to include(other_group.name)
    end
  end

  describe "POST /support_groups" do
    before { sign_in_as(user) }

    context "with valid params" do
      it "creates a group and redirects to show" do
        post support_groups_path, params: valid_params
        created = SupportGroup.order(created_at: :desc).first
        expect(response).to redirect_to(support_group_path(created))
      end

      it "increments SupportGroup count by 1" do
        expect {
          post support_groups_path, params: valid_params
        }.to change(SupportGroup, :count).by(1)
      end

      it "assigns the group to the current user" do
        post support_groups_path, params: valid_params
        expect(SupportGroup.order(created_at: :desc).first.user).to eq(user)
      end
    end

    context "with invalid params" do
      it "does not create a group" do
        expect {
          post support_groups_path, params: invalid_params
        }.not_to change(SupportGroup, :count)
      end

      it "re-renders new with 422" do
        post support_groups_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows error messages in the response body" do
        post support_groups_path, params: invalid_params
        expect(response.body).to include("errors prevented")
      end
    end
  end

  describe "GET /support_groups/:id" do
    context "as the owner" do
      before { sign_in_as(user) }

      it "returns 200" do
        get support_group_path(group)
        expect(response).to have_http_status(:ok)
      end
    end

    context "as a different user" do
      before { sign_in_as(other) }

      it "returns 404" do
        get support_group_path(group)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /support_groups/:id" do
    context "as the owner" do
      before { sign_in_as(user) }

      it "updates and redirects to show" do
        patch support_group_path(group), params: { support_group: { name: "Updated Name" } }
        expect(response).to redirect_to(support_group_path(group))
        expect(group.reload.name).to eq("Updated Name")
      end

      it "re-renders edit with 422 on invalid params" do
        patch support_group_path(group), params: { support_group: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as a different user" do
      before { sign_in_as(other) }

      it "returns 404" do
        patch support_group_path(group), params: { support_group: { name: "Hacked" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /support_groups/:id" do
    context "as the owner" do
      before { sign_in_as(user) }

      it "destroys the group and redirects to index" do
        expect {
          delete support_group_path(group)
        }.to change(SupportGroup, :count).by(-1)
        expect(response).to redirect_to(support_groups_path)
      end
    end

    context "as a different user" do
      before { sign_in_as(other) }

      it "returns 404 and does not destroy the group" do
        expect {
          delete support_group_path(group)
        }.not_to change(SupportGroup, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
