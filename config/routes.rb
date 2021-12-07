Rails.application.routes.draw do

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  devise_for :users,
    defaults: { format: :json },
    path: "",
    path_names: {
      sign_in: "api/login",
      sign_out: "api/logout",
      registration: "api/signup",
    },
    controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations",
    }
end
