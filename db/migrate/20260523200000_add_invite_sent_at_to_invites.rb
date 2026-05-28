class AddInviteSentAtToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :invite_sent_at, :datetime
  end
end
