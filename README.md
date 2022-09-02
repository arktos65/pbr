# TGW-PBR

This gem provides Ruby developers an easy approach to integrating your application with the ProductBoard API. Learn
more about [ProductBoard](https://developer.productboard.com/).  You will need an access token issued from
ProductBoard to access their API. Here's how you can [get a token](https://developer.productboard.com/#section/Authentication/Getting-a-token).

This gem is modeled on and portions of the code are forked from the [jira-ruby project](https://github.com/sumoheavy/jira-ruby)
as I liked their approach to adhering to Ruby on Rails conventions for managing resources through the API.  I created
this gem for another software project I maintain and needed a nice library to use the ProductBoard API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tgw-pbr'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tgw-pbr

## Usage

This library adheres to many of the Ruby on Rails Active Record conventions so you can implement ProductBoard
features in a variety of ways including Controllers, Views, and modules depending on your solution.

To get started, you will need an [access token](https://developer.productboard.com/#section/Authentication/Getting-a-token) from the ProductBoard API.
It is important that you keep your access token secure and **strongly** recommend that you do not hardcode the 
token in your project's codebase. There are best practice recommendations available for handling sensitive information
such as access tokens in your production environment.

### Example Usage

```ruby
require 'tgw-pbr'

# NOTE: the token should be JWT encoded
api_token = API_TOKEN_OBTAINED_FROM_PRODUCT_BOARD

options = {
  :site               => 'https://api.productboard.com',
  :context_path       => '/',
  :auth_type          => :basic,
  :default_headers    => { 'Authorization' =>  "Bearer #{api_token}",
                           'X-Version' => '1'}
}

client = ProductBoard::Client.new(options)

features = client.Features.all
```

See various code examples in the `examples` directory for more detail.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/arktos65/tgw-pbr. This project is 
intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to 
the [code of conduct](https://github.com/arktos65/tgw-pbr/blob/main/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pbr project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pbr/blob/master/CODE_OF_CONDUCT.md).
