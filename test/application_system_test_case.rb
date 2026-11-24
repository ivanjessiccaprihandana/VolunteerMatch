require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # rack_test drives the real pages without a browser, so system tests run
  # anywhere (including CI) without Chrome. Switch to :selenium for tests
  # that need JavaScript.
  driven_by :rack_test
end
