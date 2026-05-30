class AddPhoneToGuests < ActiveRecord::Migration[8.1]
  def change
    add_column :guests, :phone, :string
  end
end
