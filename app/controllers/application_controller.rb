
class ApplicationController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
    payload = token && JsonWebToken.decode(token)
    user = payload && User.find_by(id: payload[:sub])

    if user
      Current.user = user
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end