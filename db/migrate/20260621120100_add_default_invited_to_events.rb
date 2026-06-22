class AddDefaultInvitedToEvents < ActiveRecord::Migration[8.1]
  def change
    # When true, newly-created invites are auto-attached to this event. Side-specific
    # events (e.g. the bride-side Maiyaan/Haldi) set this to false so they must be
    # opted into per invite rather than blanket-attached to everyone.
    add_column :events, :default_invited, :boolean, default: true, null: false
  end
end
