require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VolunteerMatch
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    # Event times are entered and shown in Indonesian Western time (WIB).
    # Values are still stored as UTC in the database.
    config.time_zone = "Asia/Jakarta"

    # The interface is written in Indonesian.
    config.i18n.available_locales = %i[id en]
    config.i18n.default_locale = :id

    config.active_record.default_timezone = :utc
  end
end
