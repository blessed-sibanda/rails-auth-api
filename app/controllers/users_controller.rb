class UsersController < ApplicationController
  before_action :authenticate_user!, only: :show
  before_action :set_user, except: :index

  def index
    @users = User.page(params[:page]).per(User.per_page).order(:created_at)
  end

  def show
  end

  private

  def set_user
    @user = User.find params[:id]
  end
end
