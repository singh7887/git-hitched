class AddSideToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :side, :string, default: "groom", null: false
    add_index :invites, :side
  end
end
