class MapsController < ApplicationController
  def index
    victory_counts = Victory.group(:court_id, :user_id).count
    top_user_ids = victory_counts
      .group_by { |(court_id, _), _| court_id }
      .transform_values { |entries| entries.max_by { |_, count| count }&.first&.last }

    top_users = User.where(id: top_user_ids.values.compact)
                    .index_by(&:id)

    @markers = Court.where.not(lat: nil, long: nil).map do |court|
      top_user = top_users[top_user_ids[court.id]]
      top_user_image = top_user&.profile_picture&.attached? ? url_for(top_user.profile_picture) : nil

      {
        lat: court.lat,
        lng: court.long,
        name: court.name,
        address: court.address,
        url: court_path(court),
        image: court.image.attached? ? url_for(court.image) : nil,
        top_user_image: top_user_image
      }
    end
  end
end
