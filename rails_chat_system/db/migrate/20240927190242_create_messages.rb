class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.belongs_to :chat, index: true, foreign_key: true
      t.integer :message_num, null: false
      t.string :body, null: false

      t.timestamps
    end
  end
end
