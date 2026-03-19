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
    @current_user_rank = @ranked_users.index(current_user)&.+(1)
    @current_user_points = @victory_counts[current_user.id] || 0
  end

  private

  def set_court
    @court = Court.find(params[:id])
  end

  def ranked_users
    points = court_points_per_user
    user_ids = points.keys
    return User.none if user_ids.empty?

    users = User.where(id: user_ids).index_by(&:id)
    user_ids.sort_by { |id| -points[id] }.map { |id| users[id] }
  end

  def court_points_per_user
    return @court_points_per_user if @court_points_per_user

    points = {}

    # Victoires × 25
    @court.victories.group(:user_id).count.each do |user_id, count|
      points[user_id] = count * 25
    end

    # Paniers × 0.25 pour les matchs joués sur ce terrain
    court_matches = Match.joins(:meet).where(meets: { court: @court }).includes(blue_team: :users, red_team: :users)
    court_matches.each do |match|
      blue_ids = match.blue_team.users.map(&:id)
      blue_ids.each { |uid| points[uid] = ((points[uid] || 0) + match.blue_team_score * 0.25).round }

      red_ids = match.red_team.users.map(&:id)
      red_ids.each { |uid| points[uid] = ((points[uid] || 0) + match.red_team_score * 0.25).round }
    end

    @court_points_per_user = points
  end
end
