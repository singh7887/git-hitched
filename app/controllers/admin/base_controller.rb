module Admin
  class BaseController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_admin_side

    layout "admin"

    private

    # Remember the bride/groom filter in the session so it applies across all admin
    # tabs. `?side=groom|bride` sets it; `?side=all` (or invalid) clears it; no param
    # keeps whatever was last chosen. Exposed to views as @admin_side.
    def set_admin_side
      if params.key?(:side)
        requested = params[:side].to_s
        @admin_side = Invite.sides.key?(requested) ? requested : nil
        session[:admin_side] = @admin_side
      else
        @admin_side = session[:admin_side]
      end
    end

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
