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