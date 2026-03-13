class MeetsController < ApplicationController
  def index
    @meets = Meet.all
    @programs = current_user.programs
    @upcoming_meets = current_user.program_meets.where("date >= ?", Time.current).order(:date)
    @past_meets = current_user.program_meets.where("date < ?", Time.current).order(date: :desc)
  end

  def show
    @meet = Meet.find(params[:id])
    # meetable (polymorphic) est un match donc je récupére l'obet match
    @match = @meet.meetable
    # il faut que je calcule le nombre de joeur par équipe (équipe rouge et équipe bleu )
    @current_players_count = @match.blue_team.users.count + @match.red_team.users.count
  end



  def join
    @meet = Meet.find(params[:id])
    @team = Team.find(params[:team_id])
    # pour pouvoir mettre un marqueur sur l'équipe que je vais choisir
    @match = @meet.meetable

    # j'empeche le créateur du match de rejoindre l'équipe rouge
    if @match.user == current_user
    return redirect_to meet_path(@meet), alert: "En tant qu'organisateur, tu appartiens à l'équipe bleue."
    end

    # j'empeche un utilisateur de rejoindre une équipe s'il est déjà dans l'équipe rouge ou bleu
    if @match.blue_team.users.include?(current_user) || @match.red_team.users.include?(current_user)
    return redirect_to meet_path(@meet), alert: "Tu es déjà inscrit à ce match !"
    end

    # j'empeche un utilisateur de rejoindre une équipe si l'équipe est déjà complète
    if @team.users.count < @team.number_player
    UserTeam.create!(user: current_user, team: @team)
    redirect_to meet_path(@meet), notice: "Tu as rejoint l'équipe avec succès !"
    else
    redirect_to meet_path(@meet), alert: "Équipe complète !"
    end
  end

  def leave
    @meet = Meet.find(params[:id])
    @match  = @meet.meetable
    # je trouve l'association entre l'utilisateur et l'équipe (bleu ou rouge) pour pouvoir la supprimer
    user_team = UserTeam.find_by(user: current_user, team: [ @match.blue_team, @match.red_team ])

    if user_team
      user_team.destroy
      redirect_to meet_path(@meet), notice: "Tu as quitté l'équipe avec succès !"
    else
      redirect_to meet_path(@meet), alert: "Tu n'es pas inscrit à ce match !"
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
      redirect_to @program
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def meet_params
    params.require(:meet).permit(:date, :duration, :court_id)
  end
end
