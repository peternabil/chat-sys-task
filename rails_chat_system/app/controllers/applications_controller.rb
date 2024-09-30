class ApplicationsController < ApplicationController
  def index
    applications = Application.all
    render json: ApplicationRepresenter.new(applications).as_json
  end

  def create
    application = Application.new(application_params)
    if application.save
      initialize_redis_counters(application.token)

      render json: ApplicationRepresenter.new(application).as_json, status: :created
    else
      render json: { errors: application.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    render json: @application
  end

  def update
    puts params.inspect
    application = Application.find_by(token: params[:token])
    return render json: { error: "Application not found" }, status: :not_found unless application

    if application.update(application_params)
      render json: ApplicationRepresenter.new(application).as_json, status: :ok
    else
      render json: { errors: application.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def application_params
    params.require(:application).permit(:name)
  end

  def initialize_redis_counters(application_token)
    redis = Redis.new(url: ENV["REDIS_URL"])
    redis.set("chats:#{application_token}", 0)
  end
end
