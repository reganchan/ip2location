require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:country_code) }
    it { is_expected.to validate_presence_of(:ip_address) }
  end
end