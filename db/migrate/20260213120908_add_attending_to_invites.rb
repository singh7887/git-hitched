class AddAttendingToInvites < ActiveRecord::Migration[8.0]
  def change
    add_column :invites, :attending, :boolean
  end
end
