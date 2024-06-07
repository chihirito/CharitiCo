class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @coins = @user.coins
    @learning_progresses = @user.learning_progresses
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

end
