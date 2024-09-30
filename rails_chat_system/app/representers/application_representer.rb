class ApplicationRepresenter
  def initialize(applications)
    @applications = applications
  end

  def as_json
    return serialize @applications unless @applications.respond_to?(:each)

    @applications.map(&method(:serialize))
  end

  def serialize(application)
    {
      "token": application.token,
      "name": application.name,
      "chats_count": application.chats_count,
    }
  end

  private

  attr_reader :applications
end
