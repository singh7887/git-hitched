class CreateHouseholds < ActiveRecord::Migration[8.0]
  def change
    create_table :households do |t|
      t.string :invite_code, null: false
      t.string :name, null: false
      t.string :email
      t.datetime :responded_at

      t.timestamps
    end
    add_index :households, :invite_code, unique: true
  end
end
