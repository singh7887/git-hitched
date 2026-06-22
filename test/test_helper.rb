ENV["RAILS_ENV"] ||= "test"
ENV["WEDDING_INVITE_CODE"] ||= "TESTCODE"
require_relative "../config/environment"
require "rails/test_help"

# Enable all pages in test environment so existing tests pass.
PAGES_CONFIG.keys.each { |k| PAGES_CONFIG[k] = true }
PAGES_CONFIG.freeze

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  # The site-wide invite-code gate was removed; pages are now controlled by per-page
  # feature flags (enabled for tests via PAGES_CONFIG above). Kept as a no-op so the
  # existing test setups that call it continue to work.
  def authenticate_gate!
  end
end
