class MeetsController < ApplicationController
  def show
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
