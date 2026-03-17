class CourtsController < ApplicationController
  before_action :set_court

  def show
    @ranked_users = ranked_users
    @top_user = @ranked_users.first
    @victory_counts = court_points_per_user
    @user_points = @victory_counts[current_user.id] || 0
    @upcoming_meets = @court.meets.includes(:meetable).where("date >= ?", Time.current).order(:date)
  end

  def leaderboard
    @ranked_users = ranked_users
    @victory_counts = court_points_per_user
  end

  private

  def set_court
    @court = Court.find(params[:id])
  end

  def ranked_users
    User.joins(:victories)
        .where(victories: { court_id: @court.id })
        .group("users.id")
        .order("COUNT(victories.id) DESC")
  end

  def court_points_per_user
    points = {}

    # Victoires × 10
    @court.victories.group(:user_id).count.each do |user_id, count|
      points[user_id] = count * 10
    end

    # Paniers × 1 pour les matchs joués sur ce terrain
    court_matches = Match.joins(:meet).where(meets: { court: @court }).includes(blue_team: :users, red_team: :users)
    court_matches.each do |match|
      basket_score = match.blue_team_score
      blue_ids = match.blue_team.users.pluck(:id)
      blue_ids.each { |uid| points[uid] = (points[uid] || 0) + basket_score }

      basket_score = match.red_team_score
      red_ids = match.red_team.users.pluck(:id)
      red_ids.each { |uid| points[uid] = (points[uid] || 0) + basket_score }
    end

    points
  end
end
