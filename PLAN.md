# Ruby on Rails API Service Plan

## Project Overview
A Ruby on Rails API service for IP/hostname geolocation lookup using IPStack API, deployed via Docker Compose with persistent MySQL/MariaDB storage. Features include RESTful endpoints, API key authentication, Swagger documentation, and comprehensive test coverage.

## Project Structure
```
rails-api-service/
├── app/
│   ├── api/
│   │   └── v1/
│   │       └── locations_controller.rb
│   ├── models/
│   │   └── location.rb
│   └── services/
│       └── ip_lookup_service.rb
├── config/
│   ├── database.yml
│   └── routes.rb
├── db/
│   └── migrate/
│       └── 20230101000001_create_locations.rb
├── spec/
│   ├── controllers/
│   │   └── api/
│   │       └── v1/
│   │           └── locations_controller_spec.rb
│   ├── services/
│   │   └── ip_lookup_service_spec.rb
│   ├── models/
│   │   └── location_spec.rb
│   └── rails_helper.rb
├── Dockerfile
├── docker-compose.yml
├── Gemfile
├── Gemfile.lock
├── .env.example
└── swagger/
    └── v1/
        └── locations.yaml
```

## Implementation Details

### 1. Docker Configuration
**Dockerfile**
```dockerfile
FROM ruby:3.2
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
WORKDIR /rails-api-service
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
```

**docker-compose.yml**
```yaml
version: '3.8'
services:
  db:
    image: mariadb:10.6
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-rails_api_development}
      MYSQL_USER: ${MYSQL_USER:-rails}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-password}
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/rails-api-service
    environment:
      MYSQL_HOST: db
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-rails_api_development}
      MYSQL_USER: ${MYSQL_USER:-rails}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-password}
      IPSTACK_ACCESS_KEY: ${IPSTACK_ACCESS_KEY}
      API_ACCESS_KEY: ${API_ACCESS_KEY:-12345678}
    depends_on:
      - db

volumes:
  db_data:
```

### 2. Database Schema
**Migration File** (`db/migrate/20230101000001_create_locations.rb`)
```ruby
class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations do |t|
      t.string :ip_address
      t.string :hostname
      t.string :address_type
      t.string :country_code
      t.string :country_name
      t.string :region_name
      t.string :city
      t.string :zip_code
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.json :raw_response
      t.timestamps
    end
    add_index :locations, :country_code
  end
end
```

### 3. Core Components

**Location Model** (`app/models/location.rb`)
```ruby
class Location < ApplicationRecord
  validates :country_code, presence: true
  validates :ip_address, presence: true
end
```

**IP Lookup Service** (`app/services/ip_lookup_service.rb`)
```ruby
class IpLookupService
  class IpstackError < StandardError; end

  def initialize(ip_or_hostname)
    @ip_or_hostname = ip_or_hostname
  end

  def lookup
    response = Faraday.get("http://api.ipstack.com/#{@ip_or_hostname}") do |req|
      req.params['access_key'] = ENV['IPSTACK_ACCESS_KEY']
      req.params['hostname'] = 1
      req.params['language'] = 'en'
      req.params['output'] = 'json'
    end

    data = JSON.parse(response.body)
    
    if data['success'] == false
      raise IpstackError, data['error']['info']
    end

    Location.create!(
      ip_address: data['ip'],
      hostname: data['hostname'],
      address_type: data['type'],
      country_code: data['country_code'],
      country_name: data['country_name'],
      region_name: data['region_name'],
      city: data['city'],
      zip_code: data['zip'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      raw_response: data
    )
  rescue => e
    raise e
  end
end
```

**Locations Controller** (`app/api/v1/locations_controller.rb`)
```ruby
module Api
  module V1
    class LocationsController < ApplicationController
      before_action :verify_api_key
      
      def create
        location_data = location_params
        unless location_data[:ip_address] || location_data[:hostname]
          render json: { error: "Either ip_address or hostname required" }, status: :bad_request
          return
        end

        begin
          location = IpLookupService.new(
            location_data[:ip_address] || location_data[:hostname]
          ).lookup
          
          render json: {
            status: 'success',
            location_id: location.id
          }, status: :created
        rescue IpstackError => e
          render json: { error: e.message }, status: :internal_server_error
        rescue => e
          render json: { error: "Invalid input: #{e.message}" }, status: :bad_request
        end
      end

      def destroy
        location = Location.find(params[:id])
        location.destroy
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Location not found" }, status: :not_found
      end

      def index
        locations = Location.page(params[:page]).per(params[:per_page] || 20)
        render json: locations
      end

      def show
        location = Location.find(params[:id])
        render json: location
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Location not found" }, status: :not_found
      end

      private

      def location_params
        params.require(:location).permit(:ip_address, :hostname)
      end

      def verify_api_key
        unless request.headers['X-API-Key'] == ENV['API_ACCESS_KEY']
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end
    end
  end
end
```

### 4. Routes (`config/routes.rb`)
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :locations, only: [:create, :destroy, :index, :show]
    end
  end
end
```

### 5. Environment Variables (`.env.example`)
```env
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=rails_api_development
MYSQL_USER=rails
MYSQL_PASSWORD=password
IPSTACK_ACCESS_KEY=access_key_from_ipstack
API_ACCESS_KEY=12345678
```

### 6. Testing Strategy
**Request Specs** (`spec/requests/api/v1/locations_spec.rb`):
- POST with valid IP/hostname (201)
- POST with missing parameters (400)
- POST with invalid IP/hostname (400/500)
- DELETE with valid ID (204)
- DELETE with invalid ID (404)
- GET index with pagination (200)
- GET show with valid ID (200)
- GET show with invalid ID (404)
- API key verification (401)

**Unit Tests**:
- IpLookupService: Mock Faraday responses for success/error cases
- Location model: Validation tests
- Controller: Helper method tests

### 7. Setup & Deployment Instructions
```bash
# Copy environment file
cp .env.example .env
# Edit .env with actual values

# Build and start containers
docker-compose up --build

# Run migrations
docker-compose run web rails db:create db:migrate

# Run tests
docker-compose run web rspec
```

### 8. Key Features
- **Modular Design**: IP lookup service is pluggable for alternative providers
- **Error Handling**: Proper HTTP status codes (400, 404, 500) for various failure scenarios
- **Security**: API key authentication via `X-API-Key` header
- **Persistence**: MySQL data stored in Docker volume for durability
- **Documentation**: Swagger/OpenAPI interface for API exploration
- **Test Coverage**: RSpec tests for controllers, services, and models
- **Standards Compliant**: Follows Rails API best practices and Docker conventions

This plan provides a production-ready foundation that meets all specified requirements while maintaining extensibility and maintainability.
