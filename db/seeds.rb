# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require "faker"

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

  Match.create!(
    user: User.all.sample,
    red_team: red,
    blue_team: blue,
    red_team_score: rand(0..10),
    blue_team_score: rand(0..10)
  )
end

puts "#{Match.count} matches created"

# ---- COURTS ----
puts "Starting Courts seed"

Court.create!(
  name: "Basic Fit Gambetta",
  address: "233-235 Rue Léon Gambetta, Lille",
  lat: 50.628768021562784,
  long: 3.0532473518823227
)

Court.create!(
  name: "Basic Fit Rue Nationale",
  address: "85 Rue Nationale, Lille",
  lat: 50.6372,
  long: 3.0603
)

Court.create!(
  name: "Basic Fit Rue du Molinel",
  address: "31 Rue du Molinel, Lille",
  lat: 50.6376,
  long: 3.0704
)

Court.create!(
  name: "Basic Fit Rue de Douai",
  address: "124 Rue de Douai, Lille",
  lat: 50.6205,
  long: 3.0671
)

Court.create!(
  name: "Basic Fit Rue des Sarrazins",
  address: "4 bis Rue des Sarrazins, Lille",
  lat: 50.6262,
  long: 3.0468
)

Court.create!(
  name: "Basic Fit Faubourg des Postes",
  address: "Rue du Faubourg des Postes, Lille",
  lat: 50.6179,
  long: 3.0529
)

Court.create!(
  name: "Fitness Park Lille Centre",
  address: "Place des Buisses, Lille",
  lat: 50.6368,
  long: 3.0692
)

Court.create!(
  name: "Domyos Club Lille",
  address: "1 Rue du Professeur Langevin, Lille",
  lat: 50.6324,
  long: 3.0951
)

Court.create!(
  name: "Keep Cool Lille République",
  address: "6 Boulevard de la Liberté, Lille",
  lat: 50.6348,
  long: 3.0589
)

Court.create!(
  name: "Neoness Lille Flandres",
  address: "Rue de Tournai, Lille",
  lat: 50.6362,
  long: 3.0732
)

Court.create!(
  name: "L'Orange Bleue Lille",
  address: "Rue Solférino, Lille",
  lat: 50.6309,
  long: 3.0553
)

Court.create!(
  name: "CrossFit Vauban",
  address: "Quai de l'Ouest, Lille",
  lat: 50.6371,
  long: 3.0485
)

Court.create!(
  name: "CrossFit Fives",
  address: "Rue Pierre Legrand, Lille",
  lat: 50.6329,
  long: 3.0916
)

Court.create!(
  name: "Gymstreet Lille",
  address: "Rue Nationale, Lille",
  lat: 50.6375,
  long: 3.0611
)

Court.create!(
  name: "Club Moving Lille",
  address: "Boulevard de Strasbourg, Lille",
  lat: 50.6315,
  long: 3.0709
)

Court.create!(
  name: "Basic Fit Lillenium",
  address: "Centre Commercial Lillenium, Lille",
  lat: 50.6164,
  long: 3.0542
)

Court.create!(
  name: "Complexe Sportif Auguste Defaucompret",
  address: "Rue du Long Pot, Lille",
  lat: 50.6402,
  long: 3.0986
)

Court.create!(
  name: "Palais des Sports Saint Sauveur",
  address: "78 Avenue Kennedy, Lille",
  lat: 50.6298,
  long: 3.0737
)

Court.create!(
  name: "Salle Multisports Lille Sud",
  address: "Rue de Marquillies, Lille",
  lat: 50.62054,
  long: 3.037173
)

Court.create!(
  name: "Complexe Sportif Marcel Bernard",
  address: "Rue du Faubourg de Roubaix, Lille",
  lat: 50.6407,
  long: 3.0826
)

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
