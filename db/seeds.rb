require "faker"
require 'net/http'
require 'json'
require 'uri'

# Destroy all existing records to avoid duplication when running seeds multiple times
puts "Destroying existing records..."
Meet.destroy_all
Match.destroy_all
Program.destroy_all
UserTeam.destroy_all
Victory.destroy_all
Court.destroy_all
Team.destroy_all
User.destroy_all

# ---- USERS ----
puts "Starting users seed"
User.create!(
  username: "admin",
  email: "admin@test.com",
  password: "password",
  age: 30,
  gender: "Homme",
  height: 180,
  weight: 75
)

10.times do
  User.create!(
    username: Faker::Internet.username,
    email: Faker::Internet.unique.email,
    password: "password",
    age: rand(18..50),
    gender: User::GENDERS.sample,
    height: rand(155..200),
    weight: rand(50..100)
  )
end

puts "#{User.count} users created"

# ---- TEAMS ----
puts "Starting Teams seed"

10.times do
  Team.create!(
    number_player: rand(0..5)
  )
end
puts "#{Team.count} teams created"

# ---- MATCHES ----
puts "Starting Matches seed"

10.times do
  red = Team.all.sample
  blue = Team.where.not(id: red.id).sample
  team_count = rand(0..10)

  Match.create!(
    user: User.all.sample,
    red_team: red,
    blue_team: blue,
    red_team_score: team_count,
    blue_team_score: team_count
  )
end

puts "#{Match.count} matches created"

# ---- COURTS from OpenStreetMap ----
puts "Starting Courts seed via OpenStreetMap"


overpass_query = <<~QUERY
  [out:json][timeout:25];
  area["name"="Lille"]["boundary"="administrative"]->.searchArea;
  (
    node["leisure"="pitch"]["sport"="basketball"]
        ["access"!~"private|members|customers"]
        ["leisure"!~"sports_centre|school|stadium"]
        (area.searchArea);
    way["leisure"="pitch"]["sport"="basketball"]
        ["access"!~"private|members|customers"]
        ["leisure"!~"sports_centre|school|stadium"]
        (area.searchArea);
  );
  out center;
QUERY
playground_images = Dir[Rails.root.join("app/assets/images/playgrounds/*")]

uri = URI("https://overpass-api.de/api/interpreter")
response = Net::HTTP.post_form(uri, { "data" => overpass_query })
data = JSON.parse(response.body)

data["elements"].first(10).each do |element|
  lat = element["lat"] || element.dig("center", "lat")
  lon = element["lon"] || element.dig("center", "lon")

  # Reverse geocoding via Nominatim
  nominatim_uri = URI("https://nominatim.openstreetmap.org/reverse?lat=#{lat}&lon=#{lon}&format=json")
  nominatim_request = Net::HTTP::Get.new(nominatim_uri)
  nominatim_request["User-Agent"] = "DribbleCrew/1.0"
  nominatim_response = Net::HTTP.start(nominatim_uri.host, nominatim_uri.port, use_ssl: true) { |http| http.request(nominatim_request) }
  nominatim_data = JSON.parse(nominatim_response.body)

  street = nominatim_data.dig("address", "road")
  address = nominatim_data["display_name"] || "Lille"
  street_name = street&.sub(/\A(Rue|Avenue|Boulevard|Allée|Impasse|Place|Chemin|Route|Passage|Parc|Square|Villa|Voie|Résidence)\s+/i, "")
  name = street_name.present? ? "Terrain #{street_name}" : "Terrain de basketball"

  Court.find_or_create_by!(lat: lat, long: lon) do |court|
    court.name    = name
    court.address = address
    image_path = playground_images.sample
    court.image = { io: File.open(image_path), filename: File.basename(image_path) }
  end

  sleep(1) # Respecter le rate limit Nominatim (1 requête/seconde)
end

puts "#{Court.count} courts created"


# ---- PROGRAMS ----
puts "Starting Programs seed"
10.times do
  Program.create!(
    team: Team.all.sample,
    user: User.all.sample,
    title: Faker::Lorem.sentence(word_count: 3),
    content: Faker::Lorem.paragraph(sentence_count: 5),
    goal: Faker::Lorem.sentence(word_count: 5),
    level: Program::LEVELS.sample,
    active: true
  )
end

puts "#{Program.count} programs created"

# ---- MEETS ----
puts "Starting Meets seed"
10.times do
  Meet.create!(
    court: Court.all.sample,
    date: Faker::Date.forward(days: 30),
    duration: Meet::DURATIONS.sample,
    meetable: [ Program.all.sample, Match.all.sample ].sample
  )
end
puts "#{Meet.count} meets created"

# ---- VICTORIES ----
puts "Starting Victories seed"
50.times do
  Victory.create!(
    user: User.all.sample,
    court: Court.all.sample
  )
end
puts "#{Victory.count} victories created"

# ---- USER-TEAMS ----
puts "Starting User-Teams seed"
40.times do
  UserTeam.create!(
    user: User.all.sample,
    team: Team.all.sample
  )
end
puts "#{UserTeam.count} user-teams created"
