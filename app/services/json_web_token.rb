
class JsonWebToken
  ALGORITHM = "HS256"
  ACCESS_TTL = 15.minutes

  class << self
    def encode(user)
      payload = {
        sub: user.id,
        account_id: user.account_id,
        role: user.role,
        exp: ACCESS_TTL.from_now.to_i
      }
      JWT.encode(payload, secret, ALGORITHM)
    end

    # Returns the payload, or nil if the token is invalid, tampered with or expired.
    def decode(token)
      payload, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
      payload.with_indifferent_access
    rescue JWT::DecodeError # also covers JWT::ExpiredSignature
      nil
    end

    private

    def secret = Rails.application.secret_key_base
  end
end