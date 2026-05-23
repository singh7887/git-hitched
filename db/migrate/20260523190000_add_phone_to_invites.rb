class AddPhoneToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :phone, :string
    add_index :invites, :phone
  end
end
