class ProfilesController < ApplicationController
  def show
    @user = User.find(params[:id])
    # ----- Classement cards infos -----
    courts_with_stats = Court.joins(:victories)
                             .where(victories: { user: @user })
                             .group("courts.id")
                             .select("courts.*, COUNT(victories.id) AS user_victories_count")

    @classements = courts_with_stats.map do |court|
      victories_count = court.user_victories_count.to_i
      rank = User.joins(:victories)
                 .where(victories: { court: court })
                 .group("users.id")
                 .having("COUNT(victories.id) > ?", victories_count)
                 .count.length + 1
      { court: court, victories: victories_count, rank: rank }
    end.sort_by { |classement| classement[:rank] }
     # ----- Past sessions cards infos -----
    @meets = Meet.all
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to profile_path, notice: "Profil mis à jour avec succès"
    else
      render :show
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :age, :gender, :height, :weight, :profile_picture)
  end
end
