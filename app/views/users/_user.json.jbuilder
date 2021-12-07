json.extract! user, :id, :name, :created_at, :updated_at
json.avatar_url rails_blob_url(@user.avatar_image) if @user.avatar_image.persisted?
json.url user_url(user, format: :json)
