class CreateChats < ActiveRecord::Migration[7.2]
  def change
    create_table :chats do |t|
      t.belongs_to :application, index: true, foreign_key: true
      t.integer :chat_num, null: false

      t.timestamps
    end
  end
end
