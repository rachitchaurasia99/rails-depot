class ApplicationController < ActionController::Base
  include Timer
  include SessionHandler

  auto_session_timeout 5.minutes

  around_action :attach_time_in_header
  before_action :update_hit_counter, only: [:index, :show, :edit, :new]
  before_action :authorize
  before_action :set_i18n_locale_from_params
  before_action :attach_ip_in_header

  # ...
  protected

  def authorize
    unless current_user
      redirect_to login_url, notice: 'Please Log In' 
    end
  end

  def current_user
    @logged_in_user ||= User.find_by(id: session[:user_id])
  end

  def set_i18n_locale_from_params
    if params[:locale]
      if I18n.available_locales.map(&:to_s).include?(params[:locale])
        I18n.locale = params[:locale]
      else
        flash.now[:notice] = "#{params[:locale]} translation not available"
        logger.error flash.now[:notice]
      end
    end
  end
  
  def update_hit_counter
    if current_user
      @user_hit_count = current_user.hit_count.increment!(:count).count
    end

    @total_hit_count = HitCount.total_hit_count
  end

  def attach_time_in_header
    start_timer
    yield
    response.header['X-Responded-In'] = time_elapsed_in_milliseconds
  end

  def attach_ip_in_header
    @client_ip = request.ip
  end
end

