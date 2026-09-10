class Location < ActiveRecord::Base
  validates :country_code, presence: true
  validates :ip_address, presence: true
  
  serialize :raw_response, JSON
end