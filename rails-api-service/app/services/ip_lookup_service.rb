class IpLookupService
  class IpstackError < StandardError; end

  def initialize(url)
    @url = url
    @ip_or_hostname = extract_hostname(url)
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
      url: @url,
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

  private

  def extract_hostname(url)
    # If it's just an IP, return as is
    return url if url.match?(/\A\d{1,3}(\.\d{1,3}){3}\z/)

    # Extract hostname from URL like protocol://hostname:port/path
    uri = URI.parse(url)
    uri.host || url
  rescue URI::InvalidParserError
    url
  end
end