class RabbitMqConsumerWorker
  include Sidekiq::Worker

  def perform(*args)
    consumer = RabbitMqConsumer.new

    consumer.consume_chats
    consumer.consume_messages
  end
end
