class ChatsController < ApplicationController
  def index
    puts params.inspect
    application = Application.find_by(token: params[:application_token])
    if application
      @chats = application.chats
      render json: ChatRepresenter.new(@chats).as_json, status: :ok
    else
      render json: { error: "Application not found" }, status: :not_found
    end
  end

  def show
    application = Application.find_by(token: params[:application_token])
    return render json: { error: "Application not found" }, status: :not_found unless application

    chat = application.chats.find_by(chat_num: params[:chat_num])
    if chat
      @messages = chat.messages
      render json: MessageRepresenter.new(@messages).as_json, status: :ok
    else
      render json: { error: "Chat not found" }, status: :not_found
    end
  end
end
