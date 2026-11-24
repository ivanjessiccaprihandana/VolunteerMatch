class VolunteerProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :phone, format: { with: OrganizationProfile::PHONE_FORMAT }, allow_blank: true
  validates :city, length: { maximum: 100 }
  validates :availability, length: { maximum: 255 }
  validates :skills, length: { maximum: 2_000 }
  validates :bio, length: { maximum: 2_000 }
end
