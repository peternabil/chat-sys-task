class MessagesController < ApplicationController
  def index
    puts params.inspect
    if params[:q].present? && params[:token].present? && params[:chat_id].present?
      application = Application.find_by(token: params["token"])
      return render json: { error: "Application not found" }, status: :not_found unless application
      chat = application.chats.find_by(chat_num: params["chat_id"])
      return render json: { error: "Chat not found" }, status: :not_found unless chat
      @messages = Message.search(params[:q], chat.id).records.to_a
      @messages.each do |message|
        puts "Message ID: #{message.id}, Body: #{message.body}"
      end
      render json: @messages, status: :ok
    else
      return render json: { error: "Missing query or chat_id parameter" }, status: :unprocessable_entity
    end
  end

  def update
    puts params.inspect
    application = Application.find_by(token: params[:application_token])
    return render json: { error: "Application not found" }, status: :not_found unless application

    chat = application.chats.find_by(chat_num: params[:chat_chat_num])
    return render json: { error: "Chat not found" }, status: :not_found unless chat

    message = chat.messages.find_by(message_num: params[:message_num])
    if message
      if message.update(message_params)
        render json: MessageRepresenter.new(message).as_json, status: :ok
      else
        render json: { error: message.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Message not found" }, status: :not_found
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
