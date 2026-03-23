module Admin
  class BaseController < ApplicationController
    skip_before_action :require_invite_code

    http_basic_authenticate_with(
      name: ENV.fetch("ADMIN_USER", "admin"),
      password: ENV.fetch("ADMIN_PASSWORD", "password")
    )

    layout "admin"
  end
end
