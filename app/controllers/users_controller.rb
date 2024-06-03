class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @learning_progresses = @user.learning_progresses
  end
end
