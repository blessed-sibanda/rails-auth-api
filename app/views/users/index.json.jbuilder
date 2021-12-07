current_page = params.fetch(:page, 1).to_i

json._links do
  json.url users_url(page: current_page)
  json.first_page users_url(page: 1)
  json.prev_page users_url(page: current_page - 1) if (current_page > 1)
  json.next_page users_url(page: current_page + 1) if @users.next_page
  json.last_page users_url(page: @users.total_pages)
end

json._pagination do
  json.per_page User.per_page
  json.total_count @users.total_count
  json.total_pages @users.total_pages
end

json.users @users, partial: "users/user", as: :user
