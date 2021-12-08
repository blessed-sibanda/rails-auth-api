module ApiSpecsHelpers
  def json
    JSON.parse(response.body)
  end

  def token_for(user)
    post "/api/login", xhr: true, params: {
                         user: {
                           email: user.email,
                           password: user.password,
                         },
                       }
    response.headers["Authorization"]
  end
end

RSpec.configure do |c|
  c.include ApiSpecsHelpers
end
