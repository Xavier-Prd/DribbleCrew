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

10.times do
  Court.create!(
    name: Faker::Sports::Basketball.team,
    address: Faker::Address.full_address,
    lat: Faker::Address.latitude,
    long: Faker::Address.longitude
  )
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
