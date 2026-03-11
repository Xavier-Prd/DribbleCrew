class MatchesController < ApplicationController
  def new
  @match = Match.new
  #pour créer un objet meet vide associé à match
  @match.build_meet
  end

  def create
  end
end
