# Rails API Service for IP Geolocation

This project contains a Ruby on Rails API service for IP/hostname geolocation lookup using IPStack API, deployed via Docker Compose with persistent MySQL/MariaDB storage.

The actual application code is located in the `rails-api-service/` directory.

## Quick Start

1. Navigate to the application directory:
   ```bash
   cd rails-api-service
   ```

2. Copy the example environment file and edit it with your values:
   ```bash
   cp .env.example .env
   # Edit .env to set your IPSTACK_ACCESS_KEY and other variables
   ```

3. Build and start the containers:
   ```bash
   docker-compose up --build
   ```

4. In another terminal, create the database and run migrations:
   ```bash
   docker-compose run web rails db:create db:migrate
   ```

5. Run the test suite:
   ```bash
   docker-compose run web rspec
   ```

## API Endpoints

Once the service is running, you can access the following endpoints:

- `POST /api/v1/locations` - Create a new location by IP or hostname
- `DELETE /api/v1/locations/:id` - Delete a location by ID
- `GET /api/v1/locations` - List all locations (with pagination)
- `GET /api/v1/locations/:id` - Get a specific location by ID

All requests require an `X-API-Key` header with the value set in the `API_ACCESS_KEY` environment variable.

## Project Structure

- `PLAN.md` - Detailed implementation plan and specifications
- `agent.md` - Opencode agent configuration for Rails API implementation
- `rails-api-service/` - The actual Rails application

See the `rails-api-service/README.md` for more detailed information about the application structure, testing, and deployment.

## Notes

- The IP lookup service is designed to be pluggable for alternative providers.
- Database persistence is achieved via a Docker volume mounted at `/var/lib/mysql` in the MariaDB container.
- Swagger/OpenAPI documentation is available in the `rails-api-service/swagger/` directory.