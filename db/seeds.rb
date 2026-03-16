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

User.create!(
  username: "turbo_arnaud",
  email: "pierre@test.com",
  password: "password",
  age: 30,
  gender: "Homme",
  height: 180,
  weight: 75
)

fake_avatar_images = Dir[Rails.root.join("app/assets/images/fake_avatar/*")]
20.times do
  user = User.create!(
    username: Faker::Internet.username,
    email: Faker::Internet.unique.email,
    password: "password",
    age: rand(18..50),
    gender: User::GENDERS.sample,
    height: rand(155..200),
    weight: rand(50..100)
  )
  image_path = fake_avatar_images.sample
  user.profile_picture.attach(io: File.open(image_path), filename: File.basename(image_path))
end

puts "#{User.count} users created"

# ---- TEAMS ---_
puts "Starting Teams seed"

10.times do
  Team.create!(
    number_player: rand(1..5)
  )
end
puts "#{Team.count} teams created"

# ---- MATCHES ----
puts "Starting Matches seed"

10.times do
  red_team = Team.all.sample
  blue_team = Team.where(number_player: red_team.number_player).where.not(id: red_team.id).sample || Team.where.not(id: red_team.id).sample

  Match.create!(
    user: User.all.sample,
    red_team: red_team,
    blue_team: blue_team,
    red_team_score: rand(0..10),
    blue_team_score: rand(0..10)
  )
end

puts "#{Match.count} matches created"

# ---- COURTS from OpenStreetMap ----
puts "Starting Courts seed via OpenStreetMap"

# On cible les terrains de basketball dans une zone géographique spécifique (ex: Lille et environs)
CITIES = [ "Lille", "Lomme", "Lambersart" ]

# On construit une requête Overpass pour récupérer les terrains de basketball dans ces villes
# Pour chaque ville, génère un bloc de requête qui :
# - trouve la zone administrative de la ville (.city0, .city1, etc.)
# - cherche les terrains de basket publics (leisure=pitch, sport=basketball) dans cette zone
# - exclut les terrains privés (access != private|members|customers)
city_unions = CITIES.map.with_index do |city, i|
  <<~AREA
    area["name"="#{city}"]["boundary"="administrative"]->.city#{i};
    node["leisure"="pitch"]["sport"="basketball"]["access"!~"private|members|customers"](area.city#{i});
    way["leisure"="pitch"]["sport"="basketball"]["access"!~"private|members|customers"](area.city#{i});
  AREA
end.join("\n")

# On combine les blocs de requête pour créer la requête finale à envoyer à l'API Overpass
overpass_query = <<~QUERY
  [out:json][timeout:60];
  (
  #{city_unions}
  );
  out center;
QUERY

# On récupère la liste des images de terrains de basket pour les associer aux courts créés
playground_images = Dir[Rails.root.join("app/assets/images/playgrounds/*")]

uri = URI("https://overpass-api.de/api/interpreter")
response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
  http.post(uri.path, URI.encode_www_form({ "data" => overpass_query }))
end
data = JSON.parse(response.body)

data["elements"].first(50).each do |element|
  lat = element["lat"] || element.dig("center", "lat")
  lon = element["lon"] || element.dig("center", "lon")

  # Reverse geocoding via Nominatim
  nominatim_uri = URI("https://nominatim.openstreetmap.org/reverse?lat=#{lat}&lon=#{lon}&format=json")
  nominatim_request = Net::HTTP::Get.new(nominatim_uri)
  nominatim_request["User-Agent"] = "DribbleCrew/1.0"
  nominatim_response = Net::HTTP.start(nominatim_uri.host, nominatim_uri.port, use_ssl: true) { |http| http.request(nominatim_request) }
  nominatim_data = JSON.parse(nominatim_response.body)

  # Extract address components
  street = nominatim_data.dig("address", "road")
  house_number = nominatim_data.dig("address", "house_number")
  city = nominatim_data.dig("address", "city") || nominatim_data.dig("address", "town") || nominatim_data.dig("address", "village") || "Lille"
  # Construct a full(but small) address for the court
  address = [ house_number, street, city ].compact.join(", ")
  # Remove common street type prefixes for a cleaner court name
  street_name = street&.sub(/\A(Rue|Avenue|Boulevard|Allée|Impasse|Place|Chemin|Route|Passage|Parc|Square|Villa|Voie|Résidence)\s+/i, "")
  name = street_name.present? ? "Terrain #{street_name}" : "Terrain de basketball"

  # Create the court if it doesn't already exist at this location
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
    content: {
      description: Faker::Lorem.paragraph(sentence_count: 2),
      exercises: Array.new(3) { Faker::Lorem.word } # tableau de 3 mots aléatoires
      }.to_json,
    goal: Faker::Lorem.sentence(word_count: 5),
    level: Program::LEVELS.sample,
    active: true
  )
end

puts "#{Program.count} programs created"

# ---- MEETS ----
puts "Starting Meets seed"
100.times do
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
10000.times do
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
