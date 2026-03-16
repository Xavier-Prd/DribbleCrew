class MeetsController < ApplicationController
  def index
    # 1. Les rencontres planifiées
  @upcoming_meets = Meet.includes(:court, :meetable)
                        .where("date >= ?", Time.current)
                        .order(:date)

  # 2. Tous les programs de l'user
  @programs = current_user.programs

  # 3. Les rencontres passées
  @past_meets = Meet.includes(:court, :meetable)
                    .where("date < ?", Time.current)
                    .order(date: :desc)
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
     return redirect_to meet_path(@meet), alert: "Cette rencontre est déjà terminée."
   end

  # Cas 1 : Entrainement
    if @meet.meetable_type == "Program"
    # On récupère l'équipe unique du programme
    @team = @meetable.team

        if @team.users.include?(current_user)
        return redirect_to meet_path(@meet), alert: "Tu es déjà inscrit à cet entraînement !"
        end

    UserTeam.create!(user: current_user, team: @team)
    return redirect_to meet_path(@meet), notice: "Tu as rejoint l'entraînement !"

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

  def leave
  @meet = Meet.find(params[:id])
  @meetable = @meet.meetable

  # Sécurité : on bloque la tentative même si quelqu'un forge une requête manuellement
  if @meet.date <= Time.current
    return redirect_to meet_path(@meet), alert: "Cette rencontre est déjà terminée."
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
