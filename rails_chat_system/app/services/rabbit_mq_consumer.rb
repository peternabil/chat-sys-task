class RabbitMqConsumer
  def initialize
    @connection = Bunny.new(hostname: "rabbitmq")
    @connection.start
    @channel = @connection.create_channel
    @chats_buffer = []
    @messages_buffer = []
    @batch_size = Rails.application.config.rabbitmq_consumer_batch_size
  end

  def consume_chats
    queue = @channel.queue("chats_queue", durable: true)
    queue.subscribe(manual_ack: true, block: false) do |delivery_info, _properties, body|
      data = JSON.parse(body)
      @chats_buffer << data

      if @chats_buffer.size >= @batch_size
        process_chats_batch(@chats_buffer)
        @chats_buffer.clear
      end

      @channel.ack(delivery_info.delivery_tag)
    end
  end

  def consume_messages
    queue = @channel.queue("messages_queue", durable: true)
    queue.subscribe(manual_ack: true, block: false) do |delivery_info, _properties, body|
      data = JSON.parse(body)
      @messages_buffer << data

      if @messages_buffer.size >= @batch_size
        process_messages_batch(@messages_buffer)
        @messages_buffer.clear
      end

      @channel.ack(delivery_info.delivery_tag)
    end
  end

  def process_chats_batch(chats)
    Application.transaction do
      application_tokens = chats.map { |data| data["application_token"] }.uniq
      applications = Application.where(token: application_tokens).index_by(&:token)

      new_chats = chats.map do |data|
        application = applications[data["application_token"]]
        next unless application

        { chat_num: data["chat_number"], application_id: application.id, created_at: Time.current, updated_at: Time.current }
      end.compact

      Chat.insert_all(new_chats) if new_chats.any?
    end
  end

  def process_messages_batch(messages)
    Application.transaction do
      application_tokens = messages.map { |data| data["application_token"] }.uniq
      applications = Application.where(token: application_tokens).index_by(&:token)

      chat_keys = messages.map { |data| [data["application_token"], data["chat_id"]] }.uniq
      chats = Chat.joins(:application)
                  .where(application: { token: application_tokens })
                  .where(chat_num: chat_keys.map(&:last))
                  .index_by { |chat| [chat.application.token, chat.chat_num] }

      new_messages = messages.map do |data|
        application = applications[data["application_token"]]
        next unless application

        chat = chats[[data["application_token"], data["chat_id"]]]
        next unless chat

        {
          body: data["body"],
          message_num: data["message_number"],
          chat_id: chat.id,
        }
      end.compact

      Message.insert_all(new_messages) if new_messages.any?
    end
  end

  def stop
    @channel.close
    @connection.close
  end
end
