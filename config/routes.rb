Rails.application.routes.draw do
  get "/products/search", to: "products#search"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "products#search"
end
