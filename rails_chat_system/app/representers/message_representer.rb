class MessageRepresenter
  def initialize(messages)
    @messages = messages
  end

  def as_json
    return serialize @messages unless @messages.respond_to?(:each)

    @messages.map(&method(:serialize))
  end

  def serialize(message)
    {
      "id": message.message_num,
      "body": message.body,
    }
  end

  private

  attr_reader :messages
end
