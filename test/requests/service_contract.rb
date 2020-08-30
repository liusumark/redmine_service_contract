RSpec.describe "service_contracts", type: :request do
  describe "API" do
    context "logged", logged: true do
      before(:each) do
        role = Role.non_member
        role.add_permission! :view_service_contracts
      end

      it "list" do
        FactoryBot.create_list :service_contract, 2
        get service_contracts_path(format: "json")
        expect(response).to have_http_status :success
        expect(response.body).to include "limit", "offset"
        expect(response.body).to match /total_count.{,2}:2/
      end
    end

  end
end