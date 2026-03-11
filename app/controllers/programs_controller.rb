class ProgramsController < ApplicationController
SYSTEM_PROMPT = "You are a professional personal basketball coach.

Your mission is to generate a basketball program adapted to the user's level.

Duration = number of minutes
Use the user's info (height, age, weight, gender) to adapt intensity, progression, recovery, and exercise difficulty.

IMPORTANT:

STRICTLY follow the structure below.

The program must have:

A short introductory paragraph describing the program.

A list of the exercises and sequence.

Adapt intensity, progression, and exercises to the provided level and constraints.

Must be a valid parsable JSON
Return the exercises strictly as a list.
Expected structure:
Start your response with: {

{
  'title': 'Program Title',
  'content': {
    'description': 'value',
    'exercises': ['values']
  }
}
"

  def show
    @program = Program.find(params[:id])
  end

  def new
    @program = Program.new
  end

  def create
    ruby_llm_chat = RubyLLM.chat
    response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask(llm_input.to_s)
    response = JSON.parse(response.content)

    team = create_team_for_current_user!

    @program = Program.new({ title: response["title"], content: response["content"].to_json, user: current_user, team: team }.merge(program_params))

    if @program.save
      redirect_to @program, notice: "Le programme a été créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

    private

  def create_team_for_current_user!
    team = Team.create!(number_player: 1)
    UserTeam.create!(user: current_user, team: team)
  end

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
