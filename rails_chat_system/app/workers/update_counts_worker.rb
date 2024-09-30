class UpdateCountsWorker
  include Sidekiq::Worker

  def perform(*args)
    redis = Redis.new(url: ENV["REDIS_URL"])
    dirty_apps = redis.smembers("dirty:applications")
    dirty_chats = redis.smembers("dirty:chats")

    Application.transaction do
      update_application_counts(redis, dirty_apps)
      update_chat_counts(redis, dirty_chats)
    end
  end

  private

  def update_application_counts(redis, dirty_apps)
    dirty_apps.each do |app_token|
      app = Application.find_by(token: app_token)
      next unless app

      app.update(chats_count: redis.get("chats:#{app_token}").to_i)
      redis.srem("dirty:applications", app_token)
    end
  end

  def update_chat_counts(redis, dirty_chats)
    dirty_chats.each do |chat_key|
      app_token, chat_id = chat_key.split(":chat:")
      app = Application.find_by(token: app_token)
      next unless app

      chat = app.chats.find_by(chat_num: chat_id)
      next unless chat

      chat.update(messages_count: redis.get("messages:#{app_token}:chat:#{chat_id}").to_i)
      redis.srem("dirty:chats", chat_key)
    end
  end
end
