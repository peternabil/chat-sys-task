class AddCountersToApplicationsAndChats < ActiveRecord::Migration[7.2]
  def change
    add_column :applications, :chats_count, :integer, default: 0, null: false
    add_column :chats, :messages_count, :integer, default: 0, null: false
  end
end
