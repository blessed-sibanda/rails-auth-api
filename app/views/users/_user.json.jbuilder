json.extract! user, :id, :name, :created_at, :updated_at

size = params["avatar_size"] || "500"

json.url user_url(user, format: :json)

if user.avatar_image.persisted?
  json.avatar_url request.scheme + "://" + request.host + ":" + request.port.to_s + Rails.application.routes.url_helpers.rails_representation_url(user.avatar_image.variant(resize: "#{size}x#{size}").processed, only_path: true)
end
