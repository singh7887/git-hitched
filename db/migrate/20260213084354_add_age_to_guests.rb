class AddAgeToGuests < ActiveRecord::Migration[8.0]
  def change
    add_column :guests, :age, :integer
  end
end
