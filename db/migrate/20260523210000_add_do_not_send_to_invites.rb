class AddDoNotSendToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :do_not_send, :boolean, default: false, null: false
  end
end
