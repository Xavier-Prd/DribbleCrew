class MapsController < ApplicationController
  def index
    @markers = Court.where.not(lat: nil, long: nil).map do |court|
      {
        lat: court.lat,
        lng: court.long,
        info: court.name
      }
    end
  end
end
