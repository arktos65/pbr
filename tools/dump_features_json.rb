require 'tgw-pbr'
require 'json'

puts 'Enter file path to dump Features as JSON:'
json_file = gets

# NOTE: the token should be JWT encoded
api_token = ENV['PRODUCTBOARD_API_KEY']

# X-Version header is required by the ProductBoard API otherwise you will receive a 400 Bad Request
# error when consuming various API resources.
options = {
  :site               => 'https://api.productboard.com',
  :context_path       => '',                      # Leave blank
  :auth_type          => :basic,                  # :basic is the only valid value
  :http_debug         => true,                    # If true, adds additional info about verb and uri
  :default_headers    => {
    'Authorization'   => "Bearer #{api_token}",   # Requires a JWT encoded token (see ProductBoard docs)
    'X-Version'       => '1'                      # Required API version, otherwise PB ABI will throw error
  }
}

# Create client and fetch a list of feature resources from ProductBoard API
client = ProductBoard::Client.new(options)

# GET all features from ProductBoard
features = client.Features.all
puts "Writing data to #{json_file.chomp}"
File.write(json_file.chomp, JSON.dump(features))
puts "Finished"
