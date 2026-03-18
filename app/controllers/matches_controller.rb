class MatchesController < ApplicationController
  def new
    @match = Match.new
    @match.build_meet(court_id: params[:court_id])
  end

  # Action appelée quand l'organisateur valide le formulaire "Terminer le match".
  # Les scores ne sont PAS encore sauvegardés dans blue_team_score/red_team_score.
  # On les encode dans le champ qr_code sous la forme "token|blue|red" :
  # ils ne seront écrits en base qu'une fois le QR code scanné par l'équipe adverse.
  def update
    @match = Match.find(params[:id])

    blue_score = params[:match][:blue_team_score].to_i
    red_score  = params[:match][:red_team_score].to_i

    # Token aléatoire + scores encodés dans un seul champ pour éviter une migration
    confirmation_token = SecureRandom.urlsafe_base64(16)
    qr_payload = "#{confirmation_token}|#{blue_score}|#{red_score}"

    if @match.update(qr_code: qr_payload)
      redirect_to meet_path(@match.meet), notice: "Scores enregistrés ! Faites scanner le QR code par un joueur de l'équipe adverse."
    else
      redirect_to meet_path(@match.meet), alert: "Erreur lors de l'enregistrement."
    end
  end

  # Action déclenchée quand un joueur scanne le QR code.
  # Le QR code encode une URL du type : /matches/:id/confirm?token=xxx
  def confirm
    @match = Match.find(params[:id])

    # Vérification 1 : le token dans l'URL doit correspondre à celui encodé dans qr_code
    unless @match.qr_token == params[:token]
      return redirect_to meet_path(@match.meet), alert: "QR code invalide ou déjà utilisé."
    end

    # Vérification 2 : seul un joueur de l'équipe rouge peut confirmer
    unless @match.red_team.users.include?(current_user)
      return redirect_to meet_path(@match.meet), alert: "Seul un joueur de l'équipe adverse peut valider le match."
    end

    blue_score = @match.pending_blue_score
    red_score  = @match.pending_red_score

    # C'est ici que les scores sont réellement sauvegardés, et qr_code effacé
    @match.update!(
      blue_team_score: blue_score,
      red_team_score:  red_score,
      qr_code:         nil
    )

    # On détermine l'équipe gagnante (nil en cas d'égalité)
    winning_team = if blue_score > red_score
      @match.blue_team
    elsif red_score > blue_score
      @match.red_team
    end

    # On crée une Victory pour chaque joueur de l'équipe gagnante sur ce terrain.
    # find_or_create_by respecte la contrainte d'unicité user + court
    # (un joueur déjà victorieux sur ce terrain ne crée pas de doublon).
    if winning_team.present?
      court = @match.meet.court
      winning_team.users.each do |winner|
        Victory.create!(user: winner, court: court)
      end
    end

    redirect_to meet_path(@match.meet), notice: "Match validé ! Le résultat est officiel."
  end

  def create
    player_limit = params.dig(:match, :match_type).presence&.to_i
    @match = Match.new(match_params)
    if !player_limit.nil?
      my_team = create_team_for_current_user!(player_limit) # Crée une équipe pour l'utilisateur actuel
      opponent_team = Team.create!(number_player: player_limit) # Créer l'équipe adverse
    end
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
