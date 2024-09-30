class CreateApplications < ActiveRecord::Migration[7.2]
  def change
    create_table :applications do |t|
      t.string :token, null: false
      t.string :name

      t.timestamps
    end
    add_index :applications, :token, unique: true
  end
end
