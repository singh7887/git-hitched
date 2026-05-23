require "csv"
require "bigdecimal"

namespace :invites do
  desc "Import households from the wedding invite CSV (db/wedding_invite_list.csv). Idempotent. Override path with CSV_PATH=..."
  task import: :environment do
    path = ENV["CSV_PATH"].presence || Rails.root.join("db", "wedding_invite_list.csv").to_s
    abort "CSV not found at #{path}" unless File.exist?(path)

    created_invites = 0
    updated_invites = 0
    created_guests = 0
    skipped = 0

    CSV.foreach(path, headers: false) do |row|
      name = row[0].to_s.strip
      next if name.blank? || name == "Wedding Invite List" # header / blank / totals rows

      location = row[1].to_s.strip
      coming   = row[2].to_s.strip
      party    = parse_party(row[3])
      phone    = normalize_phone(row[7])
      email    = row[8].to_s.strip.downcase.presence
      address  = row[9].to_s.strip.presence

      invite = find_or_build_invite(name, location, email)
      was_new = invite.new_record?

      invite.name      = name
      invite.attending = attending_from(coming)
      invite.notes     = build_notes(location: location, coming: coming, party: party,
                                      phone: phone, address: address)
      invite.save!
      was_new ? created_invites += 1 : updated_invites += 1

      created_guests += ensure_guests(invite, name, party)
    rescue StandardError => e
      skipped += 1
      warn "Row error for #{name.inspect}: #{e.message}"
    end

    puts "Done. Invites created: #{created_invites}, updated: #{updated_invites}, " \
         "guest rows created: #{created_guests}, rows skipped: #{skipped}."
    puts "Totals now: #{Invite.count} invites, #{Guest.count} guests."
  end
end

# "Yes" => true, "No" => false, "Maybe"/blank => nil (still undecided)
def attending_from(coming)
  case coming.downcase
  when "yes" then true
  when "no"  then false
  end
end

# Party size column may be blank or non-numeric -> nil
def parse_party(raw)
  v = raw.to_s.strip
  v.match?(/\A\d+\z/) ? v.to_i : nil
end

# Excel mangles long international numbers into scientific notation
# (e.g. "9.19417E+11"). Recover the integer form; leave normal numbers as-is.
def normalize_phone(raw)
  v = raw.to_s.strip
  return nil if v.blank?
  return BigDecimal(v).to_i.to_s if v.match?(/\A\d*\.?\d+e\+?\d+\z/i)

  v
end

# No phone/location/RSVP columns exist on Invite, so preserve them in notes.
def build_notes(location:, coming:, party:, phone:, address:)
  parts = []
  parts << "Location: #{location}"            if location.present?
  parts << "Coming?: #{coming}"               if coming.present?
  parts << "Party size (invited): #{party}"   unless party.nil?
  parts << "Phone: #{phone}"                  if phone.present?
  parts << "Address: #{address}"              if address.present?
  parts.join(" | ").presence
end

# Dedup by email when present; otherwise by name + location (location lives in
# notes), so same-named households in different locations stay distinct and
# re-running the task reuses the existing record.
def find_or_build_invite(name, location, email)
  return Invite.find_or_initialize_by(email: email) if email

  marker = "Location: #{location}"
  existing = Invite.where(name: name).detect { |i| i.notes.to_s.include?(marker) }
  existing || Invite.new(name: name)
end

# Primary guest = the named household head. Add placeholder guests up to the
# invited party size so the headcount matches. Idempotent by first_name.
def ensure_guests(invite, name, party)
  created = 0

  primary = invite.guests.find_or_initialize_by(first_name: name)
  created += 1 if primary.new_record?
  primary.is_primary = true
  primary.save!

  size = party.to_i
  if size > 1
    (2..size).each do |n|
      guest = invite.guests.find_or_initialize_by(first_name: "Guest #{n}")
      next unless guest.new_record?

      guest.save!
      created += 1
    end
  end

  created
end
