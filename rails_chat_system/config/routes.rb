Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :applications, param: :token do
    resources :chats, param: :chat_num do
      resources :messages, param: :message_num do
        collection do
          get "search", to: "messages#index"
        end
      end
    end
  end
  resources :messages, only: [:index] do
    collection do
      get "search", to: "messages#index"
    end
  end
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
