require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WaiToWai
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1


    config.i18n.default_locale = :ja

    # 画像ディレクトリをアセットパイプラインに追加
    config.assets.paths << Rails.root.join("app", "assets", "images")

    # 環境変数のロード（Google Maps & GitHub API）
    config.before_configuration do
      Dotenv.load if defined?(Dotenv)

      ENV["GOOGLE_MAPS_API_KEY"] ||= Rails.application.credentials.dig(:google_maps, :api_key)
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
