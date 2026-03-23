class BackfillEventInvitesForExistingInvites < ActiveRecord::Migration[8.0]
  def up
    events = Event.all
    Invite.find_each do |invite|
      events.each do |event|
        EventInvite.find_or_create_by!(invite: invite, event: event)
      end
    end
  end

  def down
    # No-op: removing backfilled records could lose legitimate data
  end
end
