class ApplicationController < ActionController::API
  # respond_to :json

  def render_jsonapi_response(resource)
    if resource.errors.empty?
      p resource
      render resource
    else
      render resource.errors, status: 400
    end
  end
end
