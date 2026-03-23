class CreateRsvps < ActiveRecord::Migration[8.0]
  def change
    create_table :rsvps do |t|
      t.references :guest, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.boolean :attending

      t.timestamps
    end
    add_index :rsvps, [ :guest_id, :event_id ], unique: true
  end
end
