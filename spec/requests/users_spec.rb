require "rails_helper"

RSpec.describe "Users", type: :request do
  let!(:valid_attributes) do
    { user: {
      name: "Blessed",
      email: "blessed@example.com",
      password: "1234pass",
    } }
  end

  let!(:invalid_attributes) do
    { user: {
      name: "B",
      email: "blessed@example.com",
    } }
  end

  describe "POST /api/signin" do
    context "wrong credentials" do
      it "returns 401 unauthorized" do
        post "/api/login", params: {
                             user: {
                               email: "some-random-email@example.com",
                               password: "very wrong password",
                             },
                           }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "correct credentials but unconfirmed user" do
      it "returns 401 unauthorized" do
        user = create :user, :unconfirmed
        post "/api/login", params: {
                             user: {
                               email: user.email,
                               password: user.password,
                             },
                           }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "correct credentials" do
      it "returns successful response" do
        user = create :user
        post "/api/login", params: {
                             user: {
                               email: user.email,
                               password: user.password,
                             },
                           }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /users" do
    before do
      create_list :user, rand((User.per_page)..(rand(2..5) * User.per_page))
      get "/users", xhr: true
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "returns a paginated list of users without email addresses" do
      expect(json["users"].length <= User.per_page).to be_truthy
      expect(json["_pagination"]).not_to be_nil
      expect(json["_links"]).not_to be_nil
      expect(json["_pagination"]["total_pages"]).to eq((User.count.to_f / User.per_page).ceil)
      expect(json["users"][0]["email"]).to be_nil
      expect(json["users"][0]["name"]).not_to be_nil
    end

    it "orders results in ascending order of creation time" do
      expect(json["users"][0]["id"] < json["users"][-1]["id"]).to be_truthy
    end
  end

  describe "GET /users/:id" do
    let!(:user) { create :user }

    context "authenticated user" do
      before do
        @token = token_for(user)
        get "/users/#{User.all.sample.id}",
            xhr: true,
            headers: { 'Authorization': @token }
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns user email" do
        expect(json["email"]).not_to be_nil
      end
    end
    context "un-authenticated user" do
      it "returns unauthorized" do
        get "/users/#{User.all.sample.id}", xhr: true
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/signup" do
    context "with valid attributes" do
      it "creates new user" do
        expect {
          post "/api/signup", params: valid_attributes
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid attributes" do
      it "does not create new user" do
        expect {
          post "/api/signup", params: invalid_attributes
        }.to_not change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT /api/signup" do
    let!(:user) { create :user }
    context "authenticated user" do
      before do
        @token = token_for(user)
      end
      context "with valid attributes" do
        it "updates user details" do
          valid_attributes[:user][:current_password] = "my-secret"
          put "/api/signup", xhr: true, params: valid_attributes, headers: { 'Authorization': @token }
          expect(user.reload.name).to eq valid_attributes[:user][:name]
          expect(response).to have_http_status(:success)
        end
      end

      context "with valid attributes but missing current_password" do
        it "does not update user details" do
          put "/api/signup", xhr: true, params: valid_attributes, headers: { 'Authorization': @token }
          expect(user.reload.name).to_not eq valid_attributes[:user][:name]
        end
      end

      context "with invalid attributes" do
        it "does not update user details" do
          put "/api/signup", xhr: true, params: invalid_attributes, headers: { 'Authorization': @token }
          expect(user.reload.email).to_not eq invalid_attributes[:user][:email]
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
    context "un-authenticated user" do
      it "returns unauthorized" do
        put "/api/signup", xhr: true
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/logout" do
    let!(:user) { create :user }

    before do
      @token = token_for(user)
    end
    it "returns no-content" do
      delete "/api/logout", xhr: true, headers: { 'Authorization': @token }
      expect(response).to have_http_status(:no_content)
    end
    it "revokes the token" do
      delete "/api/logout", xhr: true, headers: { 'Authorization': @token }
      get "/users/#{user.id}",
          xhr: true,
          headers: { 'Authorization': @token }
      expect(response.body).to eq "revoked token"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
