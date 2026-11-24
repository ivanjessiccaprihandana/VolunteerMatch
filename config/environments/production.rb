require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Fail fast on boot when neither SECRET_KEY_BASE nor the master key is set.
  # Skipped while building the Docker image (SECRET_KEY_BASE_DUMMY), which
  # deliberately has no secrets in it.
  config.require_master_key = ENV["SECRET_KEY_BASE"].blank? && ENV["SECRET_KEY_BASE_DUMMY"].blank?

  # Serve precompiled assets from /public. Inside Docker there is no NGINX in
  # front of Puma, so this is on unless explicitly disabled.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"] != "false"
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}, immutable"
  }

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # The app sits behind a TLS-terminating proxy or load balancer in production.
  # Force HTTPS, send HSTS, and mark cookies secure. Set DISABLE_SSL=true only
  # to smoke-test the container locally over plain HTTP.
  ssl_enabled = ENV["DISABLE_SSL"] != "true"
  config.assume_ssl = ssl_enabled
  config.force_ssl = ssl_enabled
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT so the container platform collects the logs.
  config.logger = ActiveSupport::Logger.new($stdout)
                                       .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_tags = [:request_id]

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Cache store used by Rails.cache and by controller rate limiting.
  config.cache_store = :file_store, Rails.root.join("tmp/cache/store")

  # Emails are delivered in the background through Active Job.
  config.active_job.queue_adapter = :async

  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost"),
    protocol: ssl_enabled ? "https" : "http"
  }
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    domain: ENV.fetch("SMTP_DOMAIN") { ENV.fetch("APP_HOST", "localhost") },
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true
  }.compact

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Protect against DNS rebinding attacks by only accepting the configured host.
  if ENV["APP_HOST"].present?
    config.hosts = ENV["APP_HOST"].split(",").map(&:strip)
    config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  end
end
