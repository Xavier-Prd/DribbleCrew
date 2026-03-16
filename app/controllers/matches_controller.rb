class MatchesController < ApplicationController
  def new
  @match = Match.new
  # pour créer un objet meet vide associé à match
  @match.build_meet
  end

  # Action appelée quand l'organisateur valide le formulaire "Terminer le match"
  # Elle sauvegarde les scores ET génère un token unique dans qr_code.
  # Ce token sera encodé dans un QR code affiché sur la page,
  # qu'un joueur de l'équipe adverse devra scanner pour confirmer le résultat.
  def update
    @match = Match.find(params[:id])

    # On génère un token aléatoire et sécurisé qui servira de clé de confirmation
    confirmation_token = SecureRandom.urlsafe_base64(16)

    # On sauvegarde les scores ET le token en même temps
    if @match.update(finish_params.merge(qr_code: confirmation_token))
      redirect_to meet_path(@match.meet), notice: "Scores enregistrés ! Faites scanner le QR code par un joueur de l'équipe adverse."
    else
      redirect_to meet_path(@match.meet), alert: "Erreur lors de l'enregistrement."
    end
  end

  # Action déclenchée quand un joueur scanne le QR code
  # Le QR code encode une URL du type : /matches/:id/confirm?token=xxx
  def confirm
    @match = Match.find(params[:id])

    # Vérification 1 : le token dans l'URL doit correspondre à celui en base
    # (évite qu'on accède à cette URL sans avoir scanné le vrai QR code)
    unless @match.qr_code == params[:token]
      return redirect_to meet_path(@match.meet), alert: "QR code invalide ou déjà utilisé."
    end

    # Vérification 2 : seul un joueur de l'équipe rouge peut confirmer
    # (l'organisateur est toujours dans l'équipe bleue)
    unless @match.red_team.users.include?(current_user)
      return redirect_to meet_path(@match.meet), alert: "Seul un joueur de l'équipe adverse peut valider le match."
    end

    # On efface le token : qr_code nil + scores présents = match confirmé
    @match.update!(qr_code: nil)
    redirect_to meet_path(@match.meet), notice: "Match validé ! Le résultat est officiel."
  end

  def create
    player_limit = params[:match_type].to_i

    my_team = create_team_for_current_user!(player_limit) # Crée une équipe pour l'utilisateur actuel
    opponent_team = Team.create!(number_player: player_limit) # Créer l'équipe adverse
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

  # Paramètres autorisés pour terminer un match (saisie des scores uniquement)
  # On ne permet pas de modifier autre chose que les scores lors de cette action
  def finish_params
    params.require(:match).permit(:blue_team_score, :red_team_score)
  end

  def create_team_for_current_user!(limit)
    # le limit permet de ne pas etre bloqué à 1 joueur par équipe
    team = Team.create!(number_player: limit)
    UserTeam.create!(user: current_user, team: team)
    team
  end
end
