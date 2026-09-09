require 'rails_helper'
require 'faraday'

RSpec.describe IpLookupService, type: :service do
  let(:ip_address) { '8.8.8.8' }
  let(:hostname) { 'google.com' }
  let(:valid_response) do
    {
      'ip' => ip_address,
      'hostname' => hostname,
      'type' => 'ipv4',
      'country_code' => 'US',
      'country_name' => 'United States',
      'region_name' => 'California',
      'city' => 'Mountain View',
      'zip' => '94043',
      'latitude' => 37.4056,
      'longitude' => -122.0775,
      'success' => true
    }
  end

  let(:error_response) do
    {
      'success' => false,
      'error' => {
        'code' => 101,
        'info' => 'Invalid input'
      }
    }
  end

  describe '#lookup' do
    context 'with valid IP address' do
      it 'creates a location record' do
        stub_request(:get, "http://api.ipstack.com/#{ip_address}")
          .with(query: {
            'access_key' => ENV['IPSTACK_ACCESS_KEY'],
            'hostname' => '1',
            'language' => 'en',
            'output' => 'json'
          })
          .to_return(status: 200, body: valid_response.to_json, headers: {})

        expect {
          IpLookupService.new(ip_address).lookup
        }.to change(Location, :count).by(1)

        location = Location.last
        expect(location.ip_address).to eq(ip_address)
        expect(location.hostname).to eq(hostname)
        expect(location.country_code).to eq('US')
        expect(location.country_name).to eq('United States')
      end
    end

    context 'with valid hostname' do
      it 'creates a location record' do
        stub_request(:get, "http://api.ipstack.com/#{hostname}")
          .with(query: {
            'access_key' => ENV['IPSTACK_ACCESS_KEY'],
            'hostname' => '1',
            'language' => 'en',
            'output' => 'json'
          })
          .to_return(status: 200, body: valid_response.to_json, headers: {})

        expect {
          IpLookupService.new(hostname).lookup
        }.to change(Location, :count).by(1)

        location = Location.last
        expect(location.ip_address).to eq(ip_address)
        expect(location.hostname).to eq(hostname)
      end
    end

    context 'when IPStack API returns an error' do
      it 'raises an IpstackError' do
        stub_request(:get, "http://api.ipstack.com/#{ip_address}")
          .with(query: {
            'access_key' => ENV['IPSTACK_ACCESS_KEY'],
            'hostname' => '1',
            'language' => 'en',
            'output' => 'json'
          })
          .to_return(status: 200, body: error_response.to_json, headers: {})

        expect {
          IpLookupService.new(ip_address).lookup
        }.to raise_error(IpLookupService::IpstackError, /Invalid input/)
      end
    end

    context 'when the request fails' do
      it 'raises the underlying error' do
        stub_request(:get, "http://api.ipstack.com/#{ip_address}")
          .with(query: {
            'access_key' => ENV['IPSTACK_ACCESS_KEY'],
            'hostname' => '1',
            'language' => 'en',
            'output' => 'json'
          })
          .to_raise(Faraday::ConnectionFailed.new('Connection refused'))

        expect {
          IpLookupService.new(ip_address).lookup
        }.to raise_error(Faraday::ConnectionFailed)
      end
    end
  end
end