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