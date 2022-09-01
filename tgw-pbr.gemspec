require_relative 'lib/pbr/version'

Gem::Specification.new do |spec|
  spec.name          = "tgw-pbr"
  spec.version       = ProductBoard::VERSION
  spec.authors       = ["Sean M. Sullivan"]
  spec.email         = ["sean@tgwconsulting.co"]

  spec.summary       = %q{Library that makes access to the ProductBoard API simple.}
  spec.description   = %q{This library provides developers a simplified approach to using the ProductBoard API to build your own applications.}
  spec.homepage      = "https://github.com/arktos65/tgw-pbr"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/arktos65/tgw-pbr"
  spec.metadata["changelog_uri"] = "https://github.com/arktos65/tgw-pbr/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime Dependencies
  spec.add_runtime_dependency 'activesupport', '~> 6.1', '>= 6.1.6'
  spec.add_runtime_dependency 'jwt', '~> 2.4', '>= 2.4.1'
  spec.add_runtime_dependency 'multipart-post', '~> 2.2', '>= 2.2.3'
  spec.add_runtime_dependency 'oauth', '~> 0.5', '>= 0.5.0'
  spec.add_runtime_dependency 'http_logger', '~> 0.7.0'

  # Development Dependencies
  spec.add_development_dependency 'guard', '~> 2.13', '>= 2.13.0'
  spec.add_development_dependency 'guard-rspec', '~> 4.6', '>= 4.6.5'
  spec.add_development_dependency 'pry', '~> 0.14', '>= 0.14.1'
  spec.add_development_dependency 'railties', '~> 6.1', '>= 6.1.6'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0', '>= 3.0.0'
  spec.add_development_dependency 'webmock', '~> 1.18', '>= 1.18.0'
end
