class MeetsController < ApplicationController
  def index
    # Mes rencontres créées + rejointes
    user_team_ids = current_user.user_teams.pluck(:team_id)
    excluded_ids  = user_team_ids.presence || [-1]

    # 1. Les rencontres planifiées — exclut les matchs où l'user est orga ou participant
    @upcoming_meets = Meet.includes(:court, :meetable)
                          .where("date >= ?", Time.current)
                          .joins("LEFT JOIN matches ON meets.meetable_id = matches.id AND meets.meetable_type = 'Match'")
                          .where("meets.meetable_type != 'Match' OR matches.cancelled = FALSE")
                          .where("meets.meetable_type != 'Match' OR (matches.user_id != ? AND matches.blue_team_id NOT IN (?) AND matches.red_team_id NOT IN (?))",
                                 current_user.id, excluded_ids, excluded_ids)
                          .order(:date)

    # Rencontres en cours : meet démarré (date < now) ET
    #   - encore dans la fenêtre horaire (date + durée > now), OU
    #   - match non confirmé (qr_code != 'confirmed' ou nil — score pas encore validé)
    @in_progress_meets = Meet.includes(:court, :meetable)
                             .where("meets.date < ?", Time.current)
                             .joins("LEFT JOIN matches ON meets.meetable_id = matches.id AND meets.meetable_type = 'Match'")
                             .joins("LEFT JOIN programs ON meets.meetable_id = programs.id AND meets.meetable_type = 'Program'")
                             .where("matches.user_id = ? OR programs.user_id = ? OR matches.blue_team_id IN (?) OR matches.red_team_id IN (?) OR programs.team_id IN (?)",
                                    current_user.id, current_user.id, user_team_ids, user_team_ids, user_team_ids)
                             .where("(meets.date + meets.duration * interval '1 minute' > ?) OR (meets.meetable_type = 'Match' AND (matches.qr_code IS NULL OR matches.qr_code != 'confirmed'))",
                                    Time.current)
                             .distinct
                             .order(:date)

    @my_meets = Meet.includes(:court, :meetable)
                    .where("date >= ?", Time.current)
                    .joins("LEFT JOIN matches ON meets.meetable_id = matches.id AND meets.meetable_type = 'Match'")
                    .joins("LEFT JOIN programs ON meets.meetable_id = programs.id AND meets.meetable_type = 'Program'")
                    .where("matches.user_id = ? OR programs.user_id = ? OR matches.blue_team_id IN (?) OR matches.red_team_id IN (?) OR programs.team_id IN (?)",
                           current_user.id, current_user.id, user_team_ids, user_team_ids, user_team_ids)
                    .distinct
                    .order(:date)

    # 2. Tous les programs actifs de l'user
    @programs = current_user.programs.where(active: true)

  end

  def show
    @meet = Meet.find(params[:id])
    if @meet.meetable_type == "Program"
      # Au lieu de rediriger, on récupère le programme pour l'afficher dans la vue du Meet
      @program = @meet.meetable
    else
      # meetable (polymorphic) est un match donc je récupére l'obet match
      @match = @meet.meetable
      # il faut que je calcule le nombre de joeur par équipe (équipe rouge et équipe bleu )
      @current_players_count = @match.blue_team.users.count + @match.red_team.users.count
    end
  end


  def join
   @meet = Meet.find(params[:id])
   @meetable = @meet.meetable

   # Sécurité : on bloque la tentative même si quelqu'un forge une requête manuellement
   if @meet.date <= Time.current
     return redirect_to meet_path(@meet), alert: "Cette rencontre a déjà commencé. Vous ne pouvez plus la rejoindre."
   end

    # Cas 1 : Entrainement
    if @meet.meetable_type == "Program"
    # On récupère l'équipe unique du programme
    @team = @meetable.team

        if @team.users.include?(current_user)
        return redirect_to meet_path(@meet), alert: "Tu es déjà inscrit à cet entraînement !"
        end

    UserTeam.create!(user: current_user, team: @team)
    redirect_to meet_path(@meet), notice: "Tu as rejoint l'entraînement !"

    # Cas 2 : Match
    else
      @match = @meetable
      @team = Team.find(params[:team_id])

      # Empêcher l'organisateur de changer d'équipe
      if @match.user == current_user
        return redirect_to meet_path(@meet), alert: "En tant qu'organisateur, tu es déjà chez les Bleus."
      end

      # Empêcher le double enregistrement (Bleu ou Rouge)
      if @match.blue_team.users.include?(current_user) || @match.red_team.users.include?(current_user)
        return redirect_to meet_path(@meet), alert: "Tu es déjà inscrit à ce match !"
      end

      # Vérification des places
      if @team.users.count < @team.number_player
      UserTeam.create!(user: current_user, team: @team)
      redirect_to meet_path(@meet), notice: "Tu as rejoint l'équipe avec succès !"
      else
      redirect_to meet_path(@meet), alert: "Équipe complète !"
      end
    end
  end

  def switch_team
    @meet = Meet.find(params[:id])
    @match = @meet.meetable

    if @meet.meetable_type != "Match"
      return redirect_to meet_path(@meet), alert: "Action non disponible."
    end

    if @match.user == current_user
      return redirect_to meet_path(@meet), alert: "En tant qu'organisateur, tu ne peux pas changer d'équipe."
    end

    if @meet.date <= Time.current
      return redirect_to meet_path(@meet), alert: "Ce match a déjà commencé."
    end

    if @match.blue_team.users.include?(current_user)
      current_team = @match.blue_team
      target_team  = @match.red_team
    elsif @match.red_team.users.include?(current_user)
      current_team = @match.red_team
      target_team  = @match.blue_team
    else
      return redirect_to meet_path(@meet), alert: "Tu n'es pas inscrit à ce match."
    end

    if target_team.users.count >= target_team.number_player
      return redirect_to meet_path(@meet), alert: "L'équipe adverse est complète."
    end

    UserTeam.find_by!(user: current_user, team: current_team).destroy
    UserTeam.create!(user: current_user, team: target_team)
    redirect_to meet_path(@meet), notice: "Tu as changé d'équipe !"
  end

  def leave
    @meet = Meet.find(params[:id])
    @meetable = @meet.meetable
  
    # Sécurité : on bloque la tentative même si quelqu'un forge une requête manuellement
    # Exception : les matches annulés peuvent toujours être quittés
    cancelled = @meet.meetable_type == "Match" && @meetable.cancelled?
    if @meet.date <= Time.current && !cancelled
      return redirect_to meet_path(@meet), alert: "Cette rencontre a déjà commencé. Vous ne pouvez plus la quitter."
    end

    # On détermine l'équipe (ou les équipes) dans lesquelles chercher
    if @meet.meetable_type == "Program"
      # Pour un entraînement, on cherche dans l'équipe unique du programme
      target_teams = @meetable.team
    else
      # Pour un match, on cherche dans les deux équipes
      target_teams = [ @meetable.blue_team, @meetable.red_team ]
    end

    user_team = UserTeam.find_by(user: current_user, team: target_teams)

    if user_team
      user_team.destroy
      redirect_to meet_path(@meet), notice: "Vous avez quitté la session avec succès !"
    else
      redirect_to meet_path(@meet), alert: "Vous n'êtes pas inscrit à cette rencontre !"
    end
  end

  def destroy
    @meet = Meet.find(params[:id])

    if @meet.meetable_type == "Program" && @meet.meetable.user != current_user
      return redirect_to meet_path(@meet), alert: "Seul l'organisateur peut supprimer cette session."
    end

    @meet.destroy
    redirect_to meets_path, notice: "Session supprimée."
  end

  def new
    @program = Program.find(params[:program_id])
    @meet = Meet.new
  end

  def create
    @program = Program.find(params[:program_id])
    @meet = @program.meets.build(meet_params)

    if @meet.save
      redirect_to meet_path(@meet), notice: "Votre entraînement a été partagé !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def meet_params
    params.require(:meet).permit(:date, :duration, :court_id)
  end
end
