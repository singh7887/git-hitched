class RemoveInviteCodeFromHouseholds < ActiveRecord::Migration[8.0]
  def change
    remove_column :households, :invite_code, :string
  end
end
