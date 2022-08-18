require 'tgw-pbr'

# NOTE: the token should be JWT encoded
api_token = ENV['PRODUCTBOARD_API_KEY']

options = {
  :site               => 'https://api.productboard.com',
  :context_path       => '/',
  :auth_type          => :basic,
  :default_headers    => { 'Authorization' =>  "Bearer #{api_token}"}
}

client = ProductBoard::Client.new(options)

features = client.Feature.all

puts features
