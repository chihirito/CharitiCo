class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_active_storage_host
  after_action :user_activity

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :icon])
  end

  def set_active_storage_host
    ActiveStorage::Current.url_options = { host: 'localhost', port: 3000 }
  end

  def user_activity
    current_user.try :touch
  end
end
