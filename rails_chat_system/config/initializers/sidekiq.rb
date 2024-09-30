require "sidekiq-cron"

Sidekiq::Cron::Job.create(
  name: "RabbitMQ Consumer every #{Rails.application.config.rabbitmq_worker_interval} minute(s)",
  cron: "*/#{Rails.application.config.rabbitmq_worker_interval} * * * *",
  class: "RabbitMqConsumerWorker",
)

Sidekiq::Cron::Job.create(
  name: "Update chat and message counts every #{Rails.application.config.update_counts_worker_interval} minute(s)",
  cron: "*/#{Rails.application.config.update_counts_worker_interval} * * * *",
  class: "UpdateCountsWorker",
)
