require 'tgw-pbr'

# NOTE: the token should be JWT encoded
api_token = ENV['PRODUCTBOARD_API_KEY']

options = {
  :site               => 'https://api.productboard.com',
  :context_path       => '',
  :auth_type          => :basic,
  :http_debug         => true,
  :default_headers    => { 'Authorization' =>  "Bearer #{api_token}"}
}

log_options = {
  :http_logging       => true,
  :log_file           => '/tmp/producboard-http.log'
}

net_logger = ProductBoard::Logging.new(log_options)
client = ProductBoard::Client.new(options)
features = client.Features.all
puts features
