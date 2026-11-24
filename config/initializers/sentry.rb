# Error monitoring. Does nothing unless SENTRY_DSN is set.
if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = Rails.env
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", 0).to_f
    # Do not send emails, names, or IP addresses to Sentry.
    config.send_default_pii = false
  end
end
