class ProgramsController < ApplicationController
SYSTEM_PROMPT = "Vous êtes un entraîneur personnel professionnel de basketball.

Votre mission est de générer un programme d'entraînement exclusivement dédié au basketball, adapté au niveau de l'utilisateur.

Vous ne devez JAMAIS proposer d'exercices, conseils ou contenus liés à un autre sport (ping-pong, football, tennis, etc.), même si l'utilisateur en fait la demande.

Toute demande doit être interprétée comme une intention d'améliorer ses compétences en basketball uniquement.

Si l'utilisateur mentionne un autre sport, vous devez ignorer complètement ce sport et utiliser uniquement les informations utiles (niveau, condition physique, objectif) pour construire un programme de basketball.

La durée du programme doit durer maximum 120 minutes, doit être adaptée au niveau de l'utilisateur, et doit être réalisable en une seule session d'entraînement.

Utilisez les informations de l'utilisateur (taille, âge, poids, genre) pour adapter l'intensité, la progression, la récupération et la difficulté des exercices.

IMPORTANT :

Respectez STRICTEMENT la structure ci-dessous.

Le programme doit contenir :

Un court paragraphe d'introduction décrivant le programme.

Une liste des exercices et leur enchaînement.

Adaptez l'intensité, la progression et les exercices au niveau et aux contraintes fournis.

Doit être un JSON valide et analysable (parsable).
Retournez les exercices strictement sous forme de liste.

Structure attendue :
Commencez votre réponse par : {

{
  'title': 'Program Title',
  'content': {
    'description': 'value',
    'exercises': ['values']
  }
}
"

  def index
    @programs = current_user.programs.where(active: true)
    @upcoming_meets = current_user.program_meets.where("date >= ?", Time.current).order(:date)
    @past_meets = current_user.program_meets.where("date < ?", Time.current).order(date: :desc)
  end

  def show
    @program = Program.find(params[:id])
  end

  def deactivate
    @program = Program.find(params[:id])
    @program.update!(active: false)
    redirect_to meets_path, notice: "Le programme a été supprimé."
  end

  def new
    @program = Program.new
  end

  def create
    # Génération d'une réponse du LLM
    ruby_llm_chat = RubyLLM.chat
    response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask(llm_input.to_s)
    response = JSON.parse(response.content)

    # Création d'une équipe pour l'utilisateur actuel

    team = create_team_for_current_user!

    # Création d'un programme avec les données du LLM et les paramètres du formulaire

    @program = Program.new({ title: response["title"], content: response["content"], user: current_user, team: team }.merge(program_params))

    if @program.save
      redirect_to @program, notice: "Le programme a été créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

    private

  # Méthode pour créer une équipe pour l'utilisateur actuel

  def create_team_for_current_user!
    team = Team.create!(number_player: 1)
    UserTeam.create!(user: current_user, team: team)
    team
  end


  # Méthodes pour le LLM
  def program_params
    params.require(:program).permit(:goal, :level)
  end

  def llm_input = program_params.to_h.merge(
  height: current_user.height,
  age: current_user.age,
  weight: current_user.weight,
  gender: current_user.gender,
)
end
