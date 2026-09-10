class Location < ActiveRecord::Base
  validates :country_code, presence: true
  validates :url, presence: true

  serialize :raw_response, JSON
end