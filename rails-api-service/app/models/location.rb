class Location < ApplicationRecord
  validates :country_code, presence: true
  validates :ip_address, presence: true
end