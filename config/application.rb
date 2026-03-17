require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DribbleCrew
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Fuseau horaire de l'app : toutes les heures saisies et affichées sont en heure de Paris
    # Les dates sont toujours stockées en UTC en base, mais Rails fait la conversion automatiquement
    config.time_zone = "Paris"
    config.active_record.default_timezone = :local
    # Langue par défaut de l'app — utilisée par le helper l() pour traduire les dates (noms de mois, etc.)
    config.i18n.default_locale = :fr
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
