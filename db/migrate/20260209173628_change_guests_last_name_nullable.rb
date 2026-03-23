class ChangeGuestsLastNameNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :guests, :last_name, true
  end
end
