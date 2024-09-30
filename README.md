
# Chat System

Chat system for instabug task.

## Run Locally

Make sure you are in the project directory "instabug-task"


Run using docker compose

```bash
  docker compose up -d
```

### Possible error

#### If you face this error:

max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144], from elasticsearch 

run this in the ubuntu terminal:

```bash
sudo sysctl -w vm.max_map_count=262144
```
### Setup

Change the following lines in "config/application.rb" to control the batch size for the chats and messages creation as well as the interval the rabbitmq worker looks for new msgs, and the interval the sidekiq worker counts the messages and updates the "chats_count" and the "messages_count".
```
config.rabbitmq_consumer_batch_size = 2
config.rabbitmq_worker_interval = 1
config.update_counts_worker_interval = 1
```
The chats and messages won't be created until their respective queues have at least batch size items. 

The worker checking for if the batch is full runs each minute (I suggest to leave it low for testing)

The batch is currently 2 for testing purposes.

The update counts worker runs each minute to update the chats_counts and the messages_count fields for testing purposes

### Addresses
These apis will run on port 3000:
* create application "/applications"
* edit application "/applications"
* get applications "/applications"
* get chats "/applications/[token]/chats"
* get messages "/applications/[token]/chats/[chat_num]/messages"
* edit messages "/applications/[token]/chats/[chat_num]/messages/[message_num]"
* search messages "/messages?token=[token]&chat_num=[chat_num]&q=[search_term]"

These apis run on port 8080:
* create chat "/create-chat"
* create chat "/create-message"




## API Reference

#### Postman Reference

Please use these postman examples to test the full api cycle

[Postman documentation](https://documenter.getpostman.com/view/6616146/2sAXqzWdvC)