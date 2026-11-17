class OrganizationProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :organization_name, presence: true
end
