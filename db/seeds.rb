puts "Seeding events..."

jago = Event.find_or_create_by!(name: "Jago")
jago.update!(
  date: Date.new(2026, 11, 25),
  start_time: Time.zone.parse("17:00"),
  location: "JW Marriott Anaheim Resort",
  location_url: "https://www.marriott.com/en-us/hotels/laxjo-jw-marriott-anaheim-resort/overview/",
  address: "1775 S Disneyland Dr, Anaheim, CA 92802",
  maps_url: "https://maps.google.com/?q=JW+Marriott+Anaheim+Resort",
  time_description: "5:00 PM",
  attire: "Traditional Punjabi wear · bright colors encouraged",
  attire_description: "Think bold, fun, and energetic — bright kurtas, lehengas, salwar kameez. Non-Punjabi guests: colorful semi-formal or cocktail attire.",
  subtitle: "Wednesday, November 25",
  description: "The Jago — meaning \"wake up\" — is a joyful pre-wedding celebration filled with music, dancing, and family. Join the Pannu and Dhillon families as we celebrate Nuvdeep and Gulbir with song, lanterns, and late-night dancing.",
  sort_order: 1,
  image: nil
)

thanksgiving = Event.find_or_create_by!(name: "Thanksgiving Day")
thanksgiving.update!(
  date: Date.new(2026, 11, 26),
  start_time: nil,
  location: nil,
  location_url: nil,
  address: nil,
  maps_url: nil,
  time_description: "All day",
  attire: "Casual",
  attire_description: nil,
  subtitle: "Thursday, November 26",
  description: "Happy Thanksgiving! Guests are welcome to explore Anaheim and Orange County on their own. If you'd like to spend the day with the Pannu family, we are thinking of organizing something at the beach — stay tuned for details.",
  sort_order: 2,
  image: nil
)

ceremony = Event.find_or_create_by!(name: "Anand Karaj")
ceremony.update!(
  date: Date.new(2026, 11, 27),
  start_time: Time.zone.parse("08:00"),
  location: "Singh Sabha Gurudwara",
  location_url: "#",
  address: "Buena Park, CA",
  maps_url: "#",
  time_description: "8:00 AM depart hotel · 9:00 AM Milni · 10:00 AM Anand Karaj · 12:00 PM Langar",
  attire: "Modest formal — head covering required",
  attire_description: "Head coverings are required inside the Gurudwara and will be available at the entrance. Please dress modestly (covered shoulders and knees) and wear socks — shoes are removed at the door.",
  subtitle: "Friday, November 27",
  description: "The Anand Karaj — \"blissful union\" — is the Sikh wedding ceremony held in the presence of the Guru Granth Sahib, featuring Kirtan (devotional music) and four lavan (rounds) representing the couple's spiritual journey. Following the ceremony, all guests are warmly invited to Langar, a vegetarian community meal served in the tent.",
  sort_order: 3,
  image: nil
)

Event.find_by(name: "Brunch")&.destroy

reception = Event.find_or_create_by!(name: "Reception")
reception.update!(
  date: Date.new(2026, 11, 28),
  start_time: Time.zone.parse("17:00"),
  location: "JW Marriott Anaheim Resort",
  location_url: "https://www.marriott.com/en-us/hotels/laxjo-jw-marriott-anaheim-resort/overview/",
  address: "1775 S Disneyland Dr, Anaheim, CA 92802",
  maps_url: "https://maps.google.com/?q=JW+Marriott+Anaheim+Resort",
  time_description: "5:00 PM",
  attire: "Punjabi formal or Western formal",
  attire_description: "Glamorous and dressy — lehengas, sherwanis, suits, gowns. This is the big celebration, so dress the part.",
  subtitle: "Saturday, November 28",
  description: "Celebrate the newlyweds at an evening reception featuring dinner, dancing, and toasts. Join the Pannu and Dhillon families as we close out the weekend in style.",
  sort_order: 5,
  image: nil
)

puts "Seeding test invites and guests..."

pannu = Invite.find_or_create_by!(email: "test@example.com") do |i|
  i.name = "Pannu Test Family"
end

Guest.find_or_create_by!(invite: pannu, first_name: "Gulbir", last_name: "Pannu") do |g|
  g.is_primary = true
end

Guest.find_or_create_by!(invite: pannu, first_name: "Test", last_name: "Guest")

[ jago, thanksgiving, ceremony, reception ].each do |event|
  EventInvite.find_or_create_by!(invite: pannu, event: event)
end

puts "Seed complete! #{Invite.count} invites, #{Guest.count} guests, #{Event.count} events."
