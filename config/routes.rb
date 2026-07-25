Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  # RSVP flow
  get  "rsvp",                to: "rsvps#new",    as: :rsvp
  post "rsvp/lookup",         to: "rsvps#lookup", as: :rsvp_lookup
  get  "rsvp/manage",         to: "rsvps#manage", as: :rsvp_manage
  get  "rsvp/:invite_id",  to: "rsvps#show",   as: :rsvp_show
  post "rsvp/:invite_id",  to: "rsvps#update",  as: :rsvp_update

  # Content pages
  get "style-guide", to: "pages#style_guide"
  get "events",      to: "pages#events"
  get "travel",      to: "pages#travel"
  get "stay",        to: "pages#stay"
  get "explore",     to: "pages#explore"
  get "attire",      to: "pages#attire"
  get "faq",         to: "pages#faq"
  get "our-story",   to: "pages#our_story"
  get "gallery",     to: "pages#gallery"

  # Hotel bookings
  resources :hotel_bookings, only: [ :new, :create ] do
    member do
      get "success", to: "hotel_bookings#success", as: :success
      get "cancel",  to: "hotel_bookings#cancel",  as: :cancel
    end
  end

  # Stripe webhooks
  post "stripe/webhooks", to: "stripe_webhooks#create"

  # Legacy redirect
  get "details", to: redirect("/events")

  # Dev-only toggle for page feature flags
  post "dev/toggle_pages", to: "dev#toggle_pages", as: :dev_toggle_pages if Rails.env.development?

  # Admin
  namespace :admin do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    resources :invites do
      collection do
        get  :bulk_phones
        post :update_phones
      end
      member do
        post :mark_sent
        post :unmark_sent
        post :mark_skip
        post :unmark_skip
        post :merge
        post :split
      end
    end
    resources :guests
    resources :events
    resources :recommendations
    resources :hotel_bookings, only: [ :index ] do
      post :refund, on: :member
    end
    post "export",           to: "dashboard#export",           as: :export
    get  "export_links",     to: "dashboard#export_links",     as: :export_links
    get  "whatsapp_targets", to: "dashboard#whatsapp_targets", as: :whatsapp_targets, defaults: { format: :json }
    post "send_invitations", to: "dashboard#send_invitations", as: :send_invitations
    post "send_reminders",   to: "dashboard#send_reminders",   as: :send_reminders
    post "send_test_email",  to: "dashboard#send_test_email",  as: :send_test_email
    get  "import",  to: "imports#new",      as: :import
    post "import",  to: "imports#create"
  end
end
