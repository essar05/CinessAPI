require 'open-uri'

class DownloadPostersJob < ApplicationJob
  queue_as :default

  def perform()

    
    poster = open(
      'https://images-na.ssl-images-amazon.com/images/M/MV5BMjIyNTQ5NjQ1OV5BMl5BanBnXkFtZTcwODg1MDU4OA@@._V1_SY1000_CR0,0,675,1000_AL_.jpg', 
      { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE } 
    )
    IO.copy_stream(poster, Rails.root + 'public/posters/film.jpg')
    
  end
  
end
