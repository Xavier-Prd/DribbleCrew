class CourtsController < ApplicationController
  before_action :set_court

  def show
    @ranked_users = ranked_users
    @top_user = @ranked_users.first
    @victory_counts = @court.victories.group(:user_id).count
    @my_victories = @victory_counts[current_user.id] || 0
    @upcoming_meets = @court.meets.includes(:meetable).where("date >= ?", Time.current).order(:date)
  end

  def leaderboard
    @ranked_users = ranked_users
    @victory_counts = @court.victories.group(:user_id).count
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
end
