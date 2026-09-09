Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :locations, only: [:create, :destroy, :index, :show]
    end
  end
end