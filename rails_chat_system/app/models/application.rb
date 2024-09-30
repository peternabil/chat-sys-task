class Application < ApplicationRecord
  before_create :generate_token

  validates :name, presence: true
  has_many :chats

  private

  def generate_token
    self.token = SecureRandom.uuid
  end
end
