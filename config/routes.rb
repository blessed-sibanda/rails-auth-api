Rails.application.routes.draw do

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :users, only: %i[index show]
  devise_for :users,
    path: "",
    path_names: {
      sign_in: "api/login",
      sign_out: "api/logout",
      registration: "api/signup",
    },
    controllers: {
      sessions: "auth/sessions",
      registrations: "auth/registrations",
    }
end
