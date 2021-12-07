class UsersController < ApplicationController
  before_action :authenticate_user!, only: :show

  def index
    @users = User.page(params[:page]).per(User.per_page).order(:created_at)
  end

  def show
    @user = User.find params[:id]
  end
end
