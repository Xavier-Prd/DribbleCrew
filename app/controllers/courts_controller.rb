class CourtsController < ApplicationController
  def show
    @court = Court.find(params[:id])
    @meets = Meet.where(court_id: @court.id)
    @users = User.joins(:victories).group("users.id").order("COUNT(victories.id) DESC")
  end
end
