class MatchesController < ApplicationController
  def new
  @match = Match.new
  # pour créer un objet meet vide associé à match
  @match.build_meet
  end

  def create
    my_team = create_team_for_current_user! # Crée une équipe pour l'utilisateur actuel
    opponent_team = Team.create!(number_player: 1) # Créer l'équipe adverse
    @match = Match.new(match_params)
    @match.user = current_user
    @match.blue_team = my_team # on attribut toujours l'équipe bleu au créateur du match
    @match.red_team = opponent_team # équipe adverse


    if @match.save
      redirect_to meet_path(@match.meet), notice: "Match créé avec succès et equipe assignée !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def match_params
    params.require(:match).permit(:red_team_id, :blue_team_score, :red_team_score, meet_attributes: [ :date, :duration, :court_id ])
  end

  def create_team_for_current_user!
    team = Team.create!(number_player: 1)
    UserTeam.create!(user: current_user, team: team)
    team
  end
end
