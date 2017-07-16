class ApplicationController < ActionController::API
  private 
    def generic_error(message)
      render json: { response: false, message: message }
    end
end
