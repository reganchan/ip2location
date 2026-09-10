require 'rails_helper'

RSpec.describe "Api::V1::Locations", type: :request do
  let(:api_key) { '12345678' }
  let(:valid_headers) { { 'X-API-Key' => api_key } }
  let(:invalid_headers) { { 'X-API-Key' => 'invalid' } }

  describe "POST /api/v1/locations" do
    context 'with valid parameters' do
      it 'creates a location and returns success' do
        # Mock the IPStack API call
        stub_request(:get, "http://api.ipstack.com/8.8.8.8")
          .with(query: {
            'access_key' => ENV['IPSTACK_ACCESS_KEY'],
            'hostname' => '1',
            'language' => 'en',
            'output' => 'json'
          })
          .to_return(status: 200, body: {
            'ip' => '8.8.8.8',
            'hostname' => 'google.com',
            'type' => 'ipv4',
            'country_code' => 'US',
            'country_name' => 'United States',
            'region_name' => 'California',
            'city' => 'Mountain View',
            'zip' => '94043',
            'latitude' => 37.4056,
            'longitude' => -122.0775,
            'success' => true
          }.to_json, headers: {})

        expect {
          post '/api/v1/locations', params: { location: { ip_address: '8.8.8.8' } }, headers: valid_headers, as: :json
        }.to change(Location, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('success')
        expect(json['location_id']).to be_present
      end
    end

    context 'with missing ip_address and hostname' do
      it 'returns a bad request error' do
        post '/api/v1/locations', params: { location: {} }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Either ip_address or hostname required')
      end
    end

    context 'with invalid API key' do
      it 'returns unauthorized' do
        post '/api/v1/locations', params: { location: { ip_address: '8.8.8.8' } }, headers: invalid_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end

    context 'when IPStack API returns an error' do
      it 'returns internal server error' do
        allow_any_instance_of(IpLookupService).to receive(:lookup).and_raise(
          IpLookupService::IpstackError.new('API error')
        )

        post '/api/v1/locations', params: { location: { ip_address: '8.8.8.8' } }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:internal_server_error)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('API error')
      end
    end

    context 'when IPStack API raises an unexpected error' do
      it 'returns bad request' do
        allow_any_instance_of(IpLookupService).to receive(:lookup).and_raise(
          StandardError.new('Unexpected error')
        )

        post '/api/v1/locations', params: { location: { ip_address: '8.8.8.8' } }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid input: Unexpected error')
      end
    end
  end

  describe "DELETE /api/v1/locations/:id" do
    let!(:location) { Location.create!(
      ip_address: '8.8.8.8',
      hostname: 'google.com',
      address_type: 'ipv4',
      country_code: 'US',
      country_name: 'United States',
      region_name: 'California',
      city: 'Mountain View',
      zip_code: '94043',
      latitude: 37.4056,
      longitude: -122.0775,
      raw_response: '{}'
    ) }

    context 'with valid ID' do
      it 'deletes the location' do
        expect {
          delete "/api/v1/locations/#{location.id}", headers: valid_headers
        }.to change(Location, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with invalid ID' do
      it 'returns not found' do
        delete "/api/v1/locations/0", headers: valid_headers
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Location not found')
      end
    end

    context 'with invalid API key' do
      it 'returns unauthorized' do
        delete "/api/v1/locations/#{location.id}", headers: invalid_headers
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end

  describe "GET /api/v1/locations" do
    # Since we don't have factory_bot set up, we'll create them manually in a before block
    before do
      3.times do |i|
        Location.create!(
          ip_address: "8.8.8.#{i}",
          hostname: "host#{i}.com",
          address_type: 'ipv4',
          country_code: 'US',
          country_name: 'United States',
          region_name: "State#{i}",
          city: "City#{i}",
          zip_code: "0000#{i}",
          latitude: i.to_f,
          longitude: i.to_f,
          raw_response: '{}'
        )
      end
    end

    it 'returns a paginated list of locations' do
      get '/api/v1/locations', headers: valid_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
    end

    it 'respects pagination parameters' do
      get '/api/v1/locations?page=1&per_page=2', headers: valid_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.size).to eq(2)
    end

    context 'with invalid API key' do
      it 'returns unauthorized' do
        get '/api/v1/locations', headers: invalid_headers
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end

  describe "GET /api/v1/locations/:id" do
    let!(:location) { Location.create!(
      ip_address: '8.8.8.8',
      hostname: 'google.com',
      address_type: 'ipv4',
      country_code: 'US',
      country_name: 'United States',
      region_name: 'California',
      city: 'Mountain View',
      zip_code: '94043',
      latitude: 37.4056,
      longitude: -122.0775,
      raw_response: '{}'
    ) }

    context 'with valid ID' do
      it 'returns the location' do
        get "/api/v1/locations/#{location.id}", headers: valid_headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['ip_address']).to eq('8.8.8.8')
        expect(json['country_name']).to eq('United States')
      end
    end

    context 'with invalid ID' do
      it 'returns not found' do
        get "/api/v1/locations/0", headers: valid_headers
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Location not found')
      end
    end

    context 'with invalid API key' do
      it 'returns unauthorized' do
        get "/api/v1/locations/#{location.id}", headers: invalid_headers
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end
end