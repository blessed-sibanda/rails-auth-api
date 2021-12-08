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

  def get_link_by_text(html_body, text)
    doc = Nokogiri::HTML(html_body.encoded)

    loop do
      children = doc.children
      break if children.empty?

      if children.length == 1 &&
         children.first.text == text &&
         children.first.parent.name = "a"
        return children.first.parent
      end

      doc = children
    end
  end

  def check_confirmation_email_for(user)
    perform_enqueued_jobs

    email = find_email(user.email)
    expect(email).not_to be_nil
    expect(email.subject).to eq "Confirmation instructions"

    confirmation_link = get_link_by_text(email.body, "Confirm my account")
    expect(confirmation_link).to_not be_nil

    confirmation_url = confirmation_link.attributes["href"].value

    expect(user.reload.confirmed?).to be_falsey
    get confirmation_url, xhr: true
    expect(user.reload.confirmed?).to be_truthy
  end

  describe "POST /api/login" do
    context "wrong credentials" do
      it "returns 401 unauthorized" do
        post "/api/login", xhr: true, params: {
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
        post "/api/login", xhr: true, params: {
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
        post "/api/login", xhr: true, params: {
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
      expect(json["_links"]["next_page"]).not_to be_nil
      expect(json["_links"]).not_to be_nil
      total_pages = (User.count.to_f / User.per_page).ceil
      expect(json["_pagination"]["total_pages"]).to eq total_pages
      expect(json["users"][rand(User.per_page)]["email"]).to be_nil
      expect(json["users"][rand(User.per_page)]["name"]).not_to be_nil
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

  describe "POST /confirmation" do
    context "for unconfirmed user" do
      it "resends account confirmation email" do
        user = create :user, :unconfirmed
        post "/confirmation", xhr: true, params: { user: { email: user.email } }
        check_confirmation_email_for user
      end
    end

    context "for confirmed user" do
      let(:user) { create :user }

      before do
        post "/confirmation", xhr: true, params: { user: { email: user.email } }
      end

      it "does not send confirmation email" do
        expect(find_email(user.email)).to be_nil
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns helpful error message" do
        expect(json["errors"]["email"]).to eq ["was already confirmed, please try signing in"]
      end
    end
  end

  describe "POST /api/signup" do
    context "with valid attributes" do
      it "creates new user" do
        expect {
          post "/api/signup", xhr: true, params: valid_attributes
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:success)
      end

      it "sends account confirmation email" do
        post "/api/signup", xhr: true, params: valid_attributes
        user = User.find_by_email valid_attributes[:user][:email]
        check_confirmation_email_for user
      end
    end

    context "with invalid attributes" do
      it "does not create new user" do
        expect {
          post "/api/signup", xhr: true, params: invalid_attributes
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
          valid_attributes[:user][:avatar_image] = Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/user.jpg")
          expect(user.avatar_image.persisted?).to be_nil
          put "/api/signup", xhr: true, params: valid_attributes, headers: { 'Authorization': @token }
          expect(user.reload.name).to eq valid_attributes[:user][:name]
          expect(user.avatar_image.persisted?).to_not be_nil
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
