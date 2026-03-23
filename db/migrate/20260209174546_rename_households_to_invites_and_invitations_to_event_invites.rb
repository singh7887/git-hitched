class RenameHouseholdsToInvitesAndInvitationsToEventInvites < ActiveRecord::Migration[8.0]
  def change
    rename_table :households, :invites
    rename_table :invitations, :event_invites
    rename_column :guests, :household_id, :invite_id
    rename_column :event_invites, :household_id, :invite_id
  end
end
