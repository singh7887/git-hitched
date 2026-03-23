puts "Seeding events..."

welcome = Event.find_or_create_by!(name: "Welcome Dinner")
welcome.update!(
  date: Date.new(2025, 9, 19),
  start_time: Time.zone.parse("17:00"),
  location: "Château de Flapjack",
  location_url: "#",
  address: "Route de Croissant, 13990 Buttersville, France",
  maps_url: "#",
  time_description: "5:00pm",
  attire: "Garden Elegance",
  attire_description: "Elegant, effortless summer attire in soft, warm-weather fabrics.",
  subtitle: "Friday, September 19",
  description: "Join us as we gather at the Château for a relaxed welcome — golden light across the vineyards, an aperitif in the gardens and a warm start to the celebrations.",
  sort_order: 1,
  image: "venue4.jpg"
)

ceremony = Event.find_or_create_by!(name: "Ceremony")
ceremony.update!(
  date: Date.new(2025, 9, 20),
  start_time: Time.zone.parse("17:00"),
  location: "Château de Flapjack",
  location_url: "#",
  address: "Route de Croissant, 13990 Buttersville, France",
  maps_url: "#",
  time_description: "Please arrive at 4:30pm for a 5:00pm Ceremony",
  attire: "Black Tie Optional",
  attire_description: nil,
  subtitle: "Saturday, September 20",
  description: "The wedding ceremony at Château de Flapjack.",
  sort_order: 2,
  image: "venue6.jpg"
)

reception = Event.find_or_create_by!(name: "Reception")
reception.update!(
  date: Date.new(2025, 9, 20),
  start_time: Time.zone.parse("19:00"),
  location: nil,
  location_url: nil,
  address: nil,
  maps_url: nil,
  time_description: "Following the Ceremony",
  attire: "Black Tie Optional",
  attire_description: nil,
  subtitle: "Saturday, September 20",
  description: "After the aperitif, guests will be invited to continue the evening at a second location, where the celebrations will unfold with dinner and dancing.",
  sort_order: 3,
  image: "reception.png"
)

recovery = Event.find_or_create_by!(name: "Recovery")
recovery.update!(
  date: Date.new(2025, 9, 21),
  start_time: Time.zone.parse("12:00"),
  location: nil,
  location_url: nil,
  address: nil,
  maps_url: nil,
  time_description: nil,
  attire: "Casual Elegance",
  attire_description: nil,
  subtitle: "Sunday, September 21",
  description: "A relaxed afternoon — slow, sunlit and celebratory. Details to follow.",
  sort_order: 4,
  image: "venue5.jpg"
)

puts "Seeding test invites and guests..."

taylor = Invite.find_or_create_by!(email: "taylor@example.com") do |i|
  i.name = "Taylor's Test Family"
end

Guest.find_or_create_by!(invite: taylor, first_name: "Taylor", last_name: "Pepperworth") do |g|
  g.is_primary = true
end

Guest.find_or_create_by!(invite: taylor, first_name: "Taylor's", last_name: "Guest")

[ welcome, ceremony, reception, recovery ].each do |event|
  EventInvite.find_or_create_by!(invite: taylor, event: event)
end

robin = Invite.find_or_create_by!(email: "robin@example.com") do |i|
  i.name = "Robin's Test Family"
end

Guest.find_or_create_by!(invite: robin, first_name: "Robin", last_name: "Snackwell") do |g|
  g.is_primary = true
end

Guest.find_or_create_by!(invite: robin, first_name: "Robin's", last_name: "Guest")

[ welcome, ceremony, reception, recovery ].each do |event|
  EventInvite.find_or_create_by!(invite: robin, event: event)
end

puts "Seed complete! #{Invite.count} invites, #{Guest.count} guests, #{Event.count} events."
