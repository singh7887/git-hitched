class AddNotesToInvites < ActiveRecord::Migration[8.0]
  def change
    add_column :invites, :notes, :text
  end
end
