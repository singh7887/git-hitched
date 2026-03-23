class CreateGuests < ActiveRecord::Migration[8.0]
  def change
    create_table :guests do |t|
      t.references :household, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.integer :meal_choice, default: 0
      t.text :dietary_notes
      t.boolean :is_primary, default: false, null: false

      t.timestamps
    end
  end
end
