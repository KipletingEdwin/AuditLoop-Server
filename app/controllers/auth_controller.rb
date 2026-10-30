
class AuthController < ApplicationController
  skip_before_action :authenticate!, only: %i[login refresh logout]

  def login
    user = User.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password].to_s)
      render json: session_payload(user)
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # Rotates: the presented refresh token is revoked and a new pair is issued.
  def refresh
    record = RefreshToken.find_active(params[:refresh_token])
    return render json: { error: "Invalid refresh token" }, status: :unauthorized unless record

    record.revoke!
    render json: session_payload(record.user)
  end

  def logout
    RefreshToken.find_active(params[:refresh_token])&.revoke!
    head :no_content
  end

  def me
    render json: user_json(Current.user)
  end

  private

  def session_payload(user)
    {
      access_token: JsonWebToken.encode(user),
      refresh_token: RefreshToken.issue_for(user),
      expires_in: JsonWebToken::ACCESS_TTL.to_i,
      user: user_json(user)
    }
  end

  def user_json(user)
    { id: user.id, email_address: user.email_address, role: user.role, account_id: user.account_id }
  end
end