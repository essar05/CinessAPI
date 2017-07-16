class MovieController < ApplicationController
  def show
    return generic_error("Invalid id") if params[:id].to_i.to_s != params[:id]
    
    response = { 
        response: true,
        data: {
          name: "jesus", 
          type: "idk"
        }
    }
    
    render json: response
  end
  
  def search
    UpdateImdbMoviesJob.perform_later(true, [ "update_db_cache" ])
    
    render json: params[:query]
  end
  
end
