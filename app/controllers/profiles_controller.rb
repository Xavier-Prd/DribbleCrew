class ProfilesController < ApplicationController
  def show
    @user = User.find(params[:id])
    # On récupère les IDs d'équipes une seule fois et on les partage avec la vue
    # pour éviter de charger team.users dans les cartes de match
    @user_team_ids = @user.teams.pluck(:id)
    @classements   = compute_classements(@user, @user_team_ids)
    @total_points  = @user.total_points
    @best_court    = @classements.max_by { |classement| classement[:victories] }
    # Nombre de victoires de l'utilisateur (une Victory est créée à chaque match gagné)
    @won_matches   = @user.victories.count
    # On filtre les meets en SQL (uniquement ceux liés à l'utilisateur)
    # et on eager-load les associations pour éviter les requêtes N+1 dans la vue
    @past_meets    = user_past_meets(@user, @user_team_ids)
  end

  def classements
    @user = User.find(params[:id])
    @classements = compute_classements(@user, @user.teams.pluck(:id))
  end

  def sessions
    @user = User.find(params[:id])
    @user_team_ids = @user.teams.pluck(:id)
    # Même optimisation que dans show : filtre SQL + eager loading
    @past_meets = user_past_meets(@user, @user_team_ids)
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

  # Filtre en SQL les meets passés appartenant à l'utilisateur,
  # puis eager-load toutes les associations nécessaires à la vue en une passe.
  def user_past_meets(user, user_team_ids)
    # Sous-requête : programmes créés par l'utilisateur OU liés à son équipe
    program_ids = Program.where(user_id: user.id)
                         .or(Program.where(team_id: user_team_ids))
                         .select(:id)

    # Sous-requête : matchs où l'une des équipes de l'utilisateur participe
    match_ids = Match.where(blue_team_id: user_team_ids)
                     .or(Match.where(red_team_id: user_team_ids))
                     .select(:id)

    Meet.where("date + duration * interval '1 minute' < ?", Time.current)
        .where(
          "(meetable_type = 'Program' AND meetable_id IN (?)) OR (meetable_type = 'Match' AND meetable_id IN (?))",
          program_ids,
          match_ids
        )
        # eager-load :court et :meetable pour éviter les requêtes N+1 dans la vue
        .includes(:court, :meetable)
        .order(date: :desc)
  end

  def compute_classements(user, user_team_ids)
    courts_with_stats = Court.joins(:victories)
                             .where(victories: { user: user })
                             .group("courts.id")
                             .select("courts.*, COUNT(victories.id) AS user_victories_count")

    return [] if courts_with_stats.empty?

    court_ids = courts_with_stats.map(&:id)

    # Calcul des rangs en une seule requête : on récupère le nombre de victoires
    # de tous les utilisateurs sur ces terrains, puis on calcule le rang en Ruby
    all_victory_counts = Victory.where(court_id: court_ids)
                                .group(:court_id, :user_id)
                                .count
    # Résultat : { [court_id, user_id] => nb_victoires, ... }

    # Calcul du total de points de panier par terrain en une seule requête SQL,
    # en additionnant uniquement le score de l'équipe de l'utilisateur via CASE
    basket_points_by_court = if user_team_ids.any?
      team_ids_str = user_team_ids.map(&:to_i).join(",")
      Match.joins("INNER JOIN meets ON meets.meetable_id = matches.id AND meets.meetable_type = 'Match'")
           .where(meets: { court_id: court_ids })
           .where("matches.blue_team_id IN (?) OR matches.red_team_id IN (?)", user_team_ids, user_team_ids)
           .group("meets.court_id")
           .sum("CASE WHEN matches.blue_team_id IN (#{team_ids_str}) THEN COALESCE(matches.blue_team_score, 0) ELSE COALESCE(matches.red_team_score, 0) END")
      # Résultat : { court_id => total_score_panier, ... }
    else
      {}
    end

    courts_with_stats.map do |court|
      user_victories = court.user_victories_count.to_i

      # Rang : nombre d'autres utilisateurs avec plus de victoires sur ce terrain + 1
      # On utilise les données déjà chargées plutôt que de refaire une requête par terrain
      rank = all_victory_counts
               .count { |(court_id, _user_id), count| court_id == court.id && count > user_victories } + 1

      basket_points = basket_points_by_court[court.id].to_f * 0.25

      { court: court, victories: user_victories, points: ((user_victories * 25) + basket_points).round, rank: rank }
    end.sort_by { |classement| classement[:rank] }
  end
end
