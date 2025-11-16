class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy

  # Roles
  enum :role, { user: 0, moderator: 1, admin: 2 }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_validation_required?

  def self.from_omniauth(auth)
    # First, try to find by provider and uid (existing Google account)
    user = where(provider: auth.provider, uid: auth.uid).first

    # If not found, check if email exists (auto-link)
    if user.nil?
      user = find_by(email_address: auth.info.email)

      if user
        # User exists with this email, link the Google account
        user.update(
          provider: auth.provider,
          uid: auth.uid,
          avatar_url: auth.info.image,
          name: auth.info.name # Update name from Google
        )
      else
        # Create new user (no password for Google-only accounts)
        user = create(
          email_address: auth.info.email,
          name: auth.info.name,
          avatar_url: auth.info.image,
          provider: auth.provider,
          uid: auth.uid,
          role: :user
          # No password - OAuth users don't need one until they want to unlink
        )
      end
    end

    user
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  def link_google_account(auth)
    update(
      provider: auth.provider,
      uid: auth.uid,
      avatar_url: auth.info.image
    )
  end

  def unlink_google_account
    return false unless oauth_user?
    return false unless password_digest.present? # Ensure user has a password

    update(
      provider: nil,
      uid: nil
    )
  end

  def avatar_url_with_size(size = 200)
    return nil unless avatar_url.present?

    # Google profile images have a size parameter (=sXX-c)
    # Replace it with the desired size
    avatar_url.gsub(/=s\d+-c$/, "=s#{size}-c")
  end

  private

  def password_validation_required?
    # Require password validation only when password is being set
    password.present?
  end
end
