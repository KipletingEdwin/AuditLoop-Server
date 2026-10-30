
class RefreshToken < ApplicationRecord
  TTL = 7.days

  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.digest(raw) = Digest::SHA256.hexdigest(raw.to_s)

  # Returns the raw token. Only its digest is stored.
  def self.issue_for(user)
    raw = SecureRandom.urlsafe_base64(48)
    create!(user: user, token_digest: digest(raw), expires_at: TTL.from_now)
    raw
  end

  def self.find_active(raw)
    return nil if raw.blank?
    active.find_by(token_digest: digest(raw))
  end

  def revoke! = update!(revoked_at: Time.current)
end