$LOAD_PATH << __dir__

require 'active_support'
require 'active_support/inflector'
ActiveSupport::Inflector.inflections do |inflector|
  inflector.singular /status$/, 'status'
end

require 'pbr/base'
require 'pbr/base_factory'
require 'pbr/http_error'

require 'pbr/resource/features'
require 'pbr/resource/version'

require 'pbr/request_client'
require 'pbr/http_client'
require 'pbr/client'

require 'jira/railtie' if defined?(Rails)
