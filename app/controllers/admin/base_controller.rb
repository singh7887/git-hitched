module Admin
  class BaseController < ApplicationController
    before_action :authenticate_admin!

    layout "admin"

    private

    # The primary admin, plus an optional second admin login (e.g. Nuvdeep) configured
    # via ADMIN_USER_2 / ADMIN_PASSWORD_2. Both get the same full admin access.
    def admin_credentials
      creds = { ENV.fetch("ADMIN_USER", "admin") => ENV.fetch("ADMIN_PASSWORD", "password") }
      if ENV["ADMIN_USER_2"].present? && ENV["ADMIN_PASSWORD_2"].present?
        creds[ENV["ADMIN_USER_2"]] = ENV["ADMIN_PASSWORD_2"]
      end
      creds
    end

    def authenticate_admin!
      authenticate_or_request_with_http_basic("Admin") do |username, password|
        expected = admin_credentials[username]
        expected.present? && secure_match?(password, expected)
      end
    end

    # Constant-time compare over fixed-length digests (safe for differing lengths).
    def secure_match?(given, expected)
      ActiveSupport::SecurityUtils.secure_compare(
        OpenSSL::Digest::SHA256.hexdigest(given.to_s),
        OpenSSL::Digest::SHA256.hexdigest(expected.to_s)
      )
    end
  end
end
