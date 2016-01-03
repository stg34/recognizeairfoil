Rails.application.routes.draw do

  get '/' => 'search#search'
  post '/' => 'search#search'
  resources :airfoils, only: [:index]

end
