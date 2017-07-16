Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  get '/' => 'index#index'
  
  scope 'movie' do
    scope '/search/:query' do
      get '/' => 'movie#search'
    end
    scope '/:id' do
      get '/' => 'movie#show'
    end
  end
  
  root 'index#index'
end
