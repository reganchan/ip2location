# Rails API Service for IP Geolocation

This is a Ruby on Rails API service for IP/hostname geolocation lookup using IPStack API, deployed via Docker Compose with persistent MySQL/MariaDB storage.

## Setup

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your actual values, especially `IPSTACK_ACCESS_KEY`.

2. Build and start the containers:
   ```bash
   docker-compose up --build
   ```

3. Run the database migrations:
   ```bash
   docker-compose run web rails db:create db:migrate
   ```

4. Run the test suite:
   ```bash
   docker-compose run web rspec
   ```

## API Endpoints

- POST `/api/v1/locations` - Create a new location by IP or hostname
- DELETE `/api/v1/locations/:id` - Delete a location by ID
- GET `/api/v1/locations` - List all locations (with pagination)
- GET `/api/v1/locations/:id` - Get a specific location by ID

All requests require an `X-API-Key` header with the value set in the `API_ACCESS_KEY` environment variable.

## Running Tests

The test suite includes:
- Model validations for Location
- Unit tests for IpLookupService (with mocked Faraday requests)
- Request specs for all API endpoints

To run the tests:
```bash
docker-compose run web rspec
```

## Project Structure

See PLAN.md for the detailed project structure and implementation plan.

## Notes

- The IP lookup service is designed to be pluggable for alternative providers.
- Database persistence is achieved via a Docker volume mounted at `/var/lib/mysql` in the MariaDB container.
- Swagger/OpenAPI documentation is available in the `swagger/` directory.