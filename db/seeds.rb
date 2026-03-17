require "faker"
require 'net/http'
require 'json'
require 'uri'

puts "Cleaning database..."
[ Meet, Match, Program, UserTeam, Victory, Court, Team, User ].each(&:destroy_all)

# ==========================================
# 1. USERS (Total: 24)
# ==========================================
puts "Creating 4 admins..."
turbo_arnaud = User.create!(username: "turbo_arnaud", email: "pierre@test.com", password: "password", age: 30, gender: "Homme", height: 180, weight: 75)
admin = User.create!(username: "admin", email: "admin@test.com", password: "password", age: 35, gender: "Homme", height: 185, weight: 80)
coach_reda = User.create!(username: "coach_reda", email: "reda@test.com", password: "password", age: 28, gender: "Homme", height: 190, weight: 85)
expert_tom = User.create!(username: "expert_tom", email: "tom@test.com", password: "password", age: 24, gender: "Homme", height: 175, weight: 70)

fake_avatar_images = Dir[Rails.root.join("app/assets/images/fake_avatar/*")]
admin_avatar_images = Dir[Rails.root.join("app/assets/images/admin_avatar/*")]
[ turbo_arnaud, admin, coach_reda, expert_tom ].each do |u|
  image_path = admin_avatar_images.sample
  u.profile_picture.attach(io: File.open(image_path), filename: File.basename(image_path))
end

puts "Creating 20 fake users..."
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

  puts "#{User.count} users created so far..." # Affiche le nombre de users créés à chaque itération pour suivre la progression du seed, surtout utile si on a une boucle plus grande ou des opérations plus longues.
end

puts "#{User.count} admins & users created"

# ---- TEAMS ---_
puts "Starting Teams seed"

10.times do
  Team.create!(
    number_player: rand(1..5)
  )
end
puts "#{Team.count} teams created"

all_users = User.where.not(id: [ turbo_arnaud.id, admin.id, coach_reda.id, expert_tom.id ])

# ==========================================
# 2. COURTS (OpenStreetMap avec Fallback 50)
# ==========================================
puts "Fetching 50 courts from OpenStreetMap..."
playground_images = Dir[Rails.root.join("app/assets/images/playgrounds/*")]
overpass_query = "[out:json][timeout:60];(node['leisure'='pitch']['sport'='basketball'](50.55,2.85,50.75,3.25);way['leisure'='pitch']['sport'='basketball'](50.55,2.85,50.75,3.25););out center;"

begin
  uri = URI("https://overpass-api.de/api/interpreter")
  response = Net::HTTP.post_form(uri, { "data" => overpass_query })
  if response.body.start_with?("{")
    data = JSON.parse(response.body)
    data["elements"].first(50).each_with_index do |element, i|
      lat = element["lat"] || element.dig("center", "lat")
      lon = element["lon"] || element.dig("center", "lon")
      nom_uri = URI("https://nominatim.openstreetmap.org/reverse?lat=#{lat}&lon=#{lon}&format=json")
      nom_res = Net::HTTP.start(nom_uri.host, nom_uri.port, use_ssl: true) { |http| http.get(nom_uri.request_uri, { 'User-Agent' => 'DribbleCrew/1.0' }) }
      nom_data = JSON.parse(nom_res.body) rescue {}
      street = nom_data.dig("address", "road")
      city = nom_data.dig("address", "city") || nom_data.dig("address", "town") || "Lille"
      base_name = street.present? ? "Terrain #{street}" : "Terrain Basket ##{i}"
      name = Court.exists?(name: base_name) ? "#{base_name} ##{i}" : base_name
      court = Court.create!(name: name, address: "#{street}, #{city}", lat: lat, long: lon)
      court.image.attach(io: File.open(playground_images.sample), filename: "court.jpg") if playground_images.any?
      sleep(1.1) # Respecter les limites de l'API Nominatim (1 requête par seconde) pour éviter les blocages d'IP
      puts "Court created: #{court.name}"
    end
  else raise "OSM Error"
  end
rescue => e
  puts "\nOSM error. Fallback to 50 manual courts..."
  50.times do |i|
    c = Court.create!(name: "Terrain Lille ##{i}", address: "Lille", lat: 50.63 + rand(-0.03..0.03), long: 3.06 + rand(-0.03..0.03))
    c.image.attach(io: File.open(playground_images.sample), filename: "court.jpg") if playground_images.any?
    puts "Court created: #{c.name} ##{i}"
  end
end

# ==========================================
# 3. MEETS (100 total - Scores fixés à 0)
# ==========================================
puts "\nCreating 100 unique meets..."

# Generer 2 meets de matches FUTURES pour turbo_arnaud & admin
2.times do |i|
  number_players_inteam = [ 1, 3, 5 ].sample
  m = Match.create!(user: all_users.sample, blue_team: Team.create!(number_player: number_players_inteam), red_team: Team.create!(number_player: number_players_inteam), blue_team_score: 0, red_team_score: 0)
  Meet.create!(court: Court.all.sample, date: Time.current + (i + 1).days, duration: 60, meetable: m)
  UserTeam.create!(user: turbo_arnaud, team: m.blue_team)
end
2.times do |i|
  number_players_inteam = [ 1, 3, 5 ].sample
  m = Match.create!(user: all_users.sample, blue_team: Team.create!(number_player: number_players_inteam), red_team: Team.create!(number_player: number_players_inteam), blue_team_score: 0, red_team_score: 0)
  Meet.create!(court: Court.all.sample, date: Time.current + (i + 1).days, duration: 60, meetable: m)
  UserTeam.create!(user: admin, team: m.blue_team)
end
# Générer 5 meets de matches PASSés pour turbo_arnaud & admin
5.times do |i|
  number_players_inteam = [ 1, 3, 5 ].sample
  m = Match.create!(user: all_users.sample, blue_team: Team.create!(number_player: number_players_inteam), red_team: Team.create!(number_player: number_players_inteam), blue_team_score: rand(1..100), red_team_score: rand(1..100))
  meet = Meet.new(court: Court.all.sample, date: Time.current + (i - 1).days, duration: 60, meetable: m)
  meet.save!(validate: false)
  UserTeam.create!(user: turbo_arnaud, team: m.blue_team)
end
5.times do |i|
  number_players_inteam = [ 1, 3, 5 ].sample
  m = Match.create!(user: all_users.sample, blue_team: Team.create!(number_player: number_players_inteam), red_team: Team.create!(number_player: number_players_inteam), blue_team_score: rand(1..100), red_team_score: rand(1..100))
  meet = Meet.new(court: Court.all.sample, date: Time.current + (i - 1).days, duration: 60, meetable: m)
  meet.save!(validate: false)
  UserTeam.create!(user: admin, team: m.blue_team)
end
# Générer 3 meets de program FUTURES pour turbo_arnaud & admin
3.times do
  p = Program.create!(
    user: turbo_arnaud,
    title: "Workout with Coach #{Faker::Name.last_name}",
    goal: "Technique",
    level: Program::LEVELS.sample,
    active: true,
    content: { "description" => Faker::Lorem.sentence, "exercises" => [ Faker::Verb.base, Faker::Verb.base, Faker::Verb.base ] }
  )
  Meet.create!(court: Court.all.sample, date: Faker::Time.between(from: Time.current, to: 15.days.from_now), duration: 60, meetable: p)
end
3.times do
  p = Program.create!(
    user: admin,
    title: "Workout with Coach #{Faker::Name.last_name}",
    goal: "Technique",
    level: Program::LEVELS.sample,
    active: true,
    content: { "description" => Faker::Lorem.sentence, "exercises" => [ Faker::Verb.base, Faker::Verb.base, Faker::Verb.base ] }
  )
  Meet.create!(court: Court.all.sample, date: Faker::Time.between(from: Time.current, to: 15.days.from_now), duration: 60, meetable: p)
end
# Générer 3 meets de program PASSéS pour turbo_arnaud & admin
3.times do
  p = Program.create!(
    user: turbo_arnaud,
    title: "Workout with Coach #{Faker::Name.last_name}",
    goal: "Technique",
    level: Program::LEVELS.sample,
    active: true,
    content: { "description" => Faker::Lorem.sentence, "exercises" => [ Faker::Verb.base, Faker::Verb.base, Faker::Verb.base ] }
  )
  meet = Meet.new(court: Court.all.sample, date: Faker::Time.between(from: 2.days.ago, to: 1.days.ago), duration: 60, meetable: p)
  meet.save!(validate: false)
end
3.times do
  p = Program.create!(
    user: admin,
    title: "Workout with Coach #{Faker::Name.last_name}",
    goal: "Technique",
    level: Program::LEVELS.sample,
    active: true,
    content: { "description" => Faker::Lorem.sentence, "exercises" => [ Faker::Verb.base, Faker::Verb.base, Faker::Verb.base ] }
  )
  meet = Meet.new(court: Court.all.sample, date: Faker::Time.between(from: 2.days.ago, to: 1.days.ago), duration: 60, meetable: p)
  meet.save!(validate: false)
end

# 10 meets de matches passés
10.times do
  number_players_inteam = [ 1, 3, 5 ].sample
  m = Match.create!(
    user: all_users.sample,
    blue_team: Team.create!(number_player: number_players_inteam),
    red_team: Team.create!(number_player: number_players_inteam),
    blue_team_score: rand(1..99),
    red_team_score: rand(1..99)
  )
  meet = Meet.new(court: Court.all.sample, date: Faker::Time.between(from: 2.days.ago, to: 1.days.ago), duration: Meet::DURATIONS.sample, meetable: m)
  meet.save!(validate: false)
end

# 50 meets de matches futures
50.times do
  number_players_inteam = [ 1, 3, 5 ].sample
  m = Match.create!(
    user: all_users.sample,
    blue_team: Team.create!(number_player: number_players_inteam),
    red_team: Team.create!(number_player: number_players_inteam),
    blue_team_score: 0,
    red_team_score: 0
  )
  Meet.create!(court: Court.all.sample, date: Faker::Time.between(from: Time.current, to: 15.days.from_now), duration: Meet::DURATIONS.sample, meetable: m)
end

# 20 meets de Programs (pas de score, pas d'équipe, juste un meet pour un programme d'entraînement)
20.times do
  # On crée un objet Program unique (Hash pour content, pas de .to_json)
  p = Program.create!(
    user: all_users.sample,
    title: "Workout with Coach #{Faker::Name.last_name}",
    goal: "Technique",
    level: Program::LEVELS.sample,
    active: true,
    content: { "description" => Faker::Lorem.sentence, "exercises" => [ Faker::Verb.base, Faker::Verb.base, Faker::Verb.base ] }
  )
  Meet.create!(court: Court.all.sample, date: Faker::Time.between(from: Time.current, to: 15.days.from_now), duration: 60, meetable: p)
end

# ==========================================
# 4. VICTORIES (10 000)
# ==========================================
puts "Inserting 10,000 victories..."
victories = []
10.times do
  1000.times { victories << { user_id: User.all.sample.id, court_id: Court.all.sample.id, created_at: Time.current, updated_at: Time.current } }
  Victory.insert_all(victories)
  victories = []
  print "."
end

# ==========================================
# 5. INSCRIPTIONS ALÉATOIRES (40)
# ==========================================
puts "\nAdding 40 random player inscriptions..."
40.times do
  t = Team.where.not(number_player: 99).sample
  u = all_users.sample
  UserTeam.create(user: u, team: t) if t && t.users.count < t.number_player && !t.users.include?(u)
end

puts "\nSeed finished!"
