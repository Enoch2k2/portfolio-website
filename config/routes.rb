Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "sitemap.xml" => "api/v1/public/sitemap#index", defaults: { format: :xml }

  namespace :api do
    namespace :v1 do
      namespace :public do
        resource :site_content, only: :show
        resources :profile_sections, only: :index
        resources :blog_posts, only: %i[index show], param: :slug
        resources :availability, only: :index
        resources :meetings, only: %i[create show]
        resources :contacts, only: :create
      end

      namespace :admin do
        resource :session, only: :create
        resources :blog_posts, except: :new
        resources :profile_sections, except: :new
        resources :availability_rules, except: :new
        resources :meetings, only: %i[index show]
        resource :site_content, only: :show do
          post :hero_photo
          delete :hero_photo, action: :destroy_hero_photo
          post :resume
          delete :resume, action: :destroy_resume
        end

        namespace :integrations do
          get :status, to: "oauth#status"
          post :google_exchange, to: "oauth#google_exchange"
          post :zoom_exchange, to: "oauth#zoom_exchange"
          post :google_refresh, to: "oauth#google_refresh"
          post :zoom_refresh, to: "oauth#zoom_refresh"
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
