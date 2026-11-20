ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Keep fixtures sequential on Windows. Parallel fixture loading can cause
  # PostgreSQL connection and transaction errors once the suite exceeds the
  # Rails parallelization threshold.

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
