class AddPartySizeToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :party_size, :integer
  end
end
