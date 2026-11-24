class OrganizationProfile < ApplicationRecord
  PHONE_FORMAT = /\A\+?[0-9\s\-()]{6,20}\z/

  belongs_to :user

  normalizes :website, with: ->(url) { url.to_s.strip.presence }

  validates :user_id, uniqueness: true
  validates :organization_name, presence: true, length: { maximum: 150 }
  validates :phone, format: { with: PHONE_FORMAT }, allow_blank: true
  validates :city, length: { maximum: 100 }
  validates :description, length: { maximum: 5_000 }
  # Only http(s) links, so the value is safe to render as a link.
  validates :website,
            format: { with: %r{\Ahttps?://[^\s/$.?#].[^\s]*\z}i },
            length: { maximum: 255 },
            allow_blank: true

  scope :verified, -> { where(verified: true) }
end
