require "rails_helper"

RSpec.describe "Charters#print", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:group) { create(:support_group, :with_charter, user: user) }

  describe "as the owner" do
    before { sign_in_as(user) }

    it "GET /support_groups/:id/charter/print returns 200 and renders the print layout" do
      get print_support_group_charter_path(group)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Charter")
    end

    it "response body does not include the navbar" do
      get print_support_group_charter_path(group)
      expect(response.body).not_to include("navbar")
    end

    it "returns 404 when the group has no charter" do
      group_without_charter = create(:support_group, user: user)
      get print_support_group_charter_path(group_without_charter)
      expect(response).to have_http_status(:not_found)
    end
  end

  context "as a different user" do
    before { sign_in_as(other) }

    it "returns 404 for a different user's group" do
      get print_support_group_charter_path(group)
      expect(response).to have_http_status(:not_found)
    end
  end

  context "unauthenticated" do
    it "redirects to sign in" do
      get print_support_group_charter_path(group)
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
