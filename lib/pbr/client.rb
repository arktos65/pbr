require 'json'
require 'forwardable'
require 'ostruct'

module ProductBoard
  # This class is the main access point for all JIRA::Resource instances.
  #
  # The client must be initialized with an options hash containing
  # configuration options. The available options are:
  #
  #   :site               => 'http://localhost:2990',
  #   :context_path       => '/jira',
  #   NO :signature_method   => 'RSA-SHA1',
  #   NO :request_token_path => "/plugins/servlet/oauth/request-token",
  #   NO :authorize_path     => "/plugins/servlet/oauth/authorize",
  #   NO :access_token_path  => "/plugins/servlet/oauth/access-token",
  #   NO :private_key        => nil,
  #   NO :private_key_file   => "rsakey.pem",
  #   :rest_base_path     => "/rest/api/2",
  #   NO :consumer_key       => nil,
  #   NO :consumer_secret    => nil,
  #   :ssl_verify_mode    => OpenSSL::SSL::VERIFY_PEER,
  #   :ssl_version        => nil,
  #   :use_ssl            => true,
  #   NO :username           => nil,
  #   NO :password           => nil,
  #   :auth_type          => :jwt,
  #   :jwt_token          => nil,
  #   :proxy_address      => nil,
  #   :proxy_port         => nil,
  #   :proxy_username     => nil,
  #   :proxy_password     => nil,
  #   :use_cookies        => nil,
  #   :additional_cookies => nil,
  #   :default_headers    => {},
  #   NO :use_client_cert    => false,
  #   :read_timeout       => nil,
  #   :http_debug         => false,
  #   NO :shared_secret      => nil,
  #   NO :cert_path          => nil,
  #   NO :key_path           => nil,
  #   NO :ssl_client_cert    => nil,
  #   NO :ssl_client_key     => nil
  #
  # See the JIRA::Base class methods for all of the available methods on these accessor
  # objects.

  class Client
    extend Forwardable

    # The OAuth::Consumer instance returned by the OauthClient
    #
    # The authenticated client instance returned by the respective client type
    # (Oauth, Basic)
    attr_accessor :consumer, :request_client, :http_debug, :cache

    # The configuration options for this client instance
    attr_reader :options

    def_delegators :@request_client, :init_access_token, :set_access_token, :set_request_token, :request_token,
                   :access_token, :authenticated?

    DEFINED_OPTIONS = [
      :site,
      :context_path,
      #:signature_method,
      #:request_token_path,
      #:authorize_path,
      #:access_token_path,
      #:private_key,
      #:private_key_file,
      :rest_base_path,
      #:consumer_key,
      #:consumer_secret,
      :ssl_verify_mode,
      :ssl_version,
      :use_ssl,
      :username,
      :password,
      :auth_type,
      :proxy_address,
      :proxy_port,
      :proxy_username,
      :proxy_password,
      :use_cookies,
      :additional_cookies,
      :default_headers,
      #:use_client_cert,
      :read_timeout,
      :http_debug,
      #:issuer,
      #:base_url,
      :shared_secret,
      #:cert_path,
      #:key_path,
      #:ssl_client_cert,
      #:ssl_client_key
    ].freeze

    DEFAULT_OPTIONS = {
      site: 'htts://api.productboard.com',
      context_path: '/',
      rest_base_path: '/rest/api/2',
      ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER,
      use_ssl: true,
      auth_type: :basic,
      http_debug: false,
      use_cookies: false,
      default_headers: {}
    }.freeze

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @options = options
      @options[:rest_base_path] = @options[:context_path] + @options[:rest_base_path]

      unknown_options = options.keys.reject { |o| DEFINED_OPTIONS.include?(o) }
      raise ArgumentError, "Unknown option(s) given: #{unknown_options}" unless unknown_options.empty?

      # if options[:use_client_cert]
      #   @options[:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(@options[:cert_path])) if @options[:cert_path]
      #   @options[:ssl_client_key] = OpenSSL::PKey::RSA.new(File.read(@options[:key_path])) if @options[:key_path]
      #
      #   raise ArgumentError, 'Options: :cert_path or :ssl_client_cert must be set when :use_client_cert is true' unless @options[:ssl_client_cert]
      #   raise ArgumentError, 'Options: :key_path or :ssl_client_key must be set when :use_client_cert is true' unless @options[:ssl_client_key]
      # end

      case options[:auth_type]
      when :basic
        @request_client = HttpClient.new(@options)
      else
        raise ArgumentError, 'Options: ":auth_type" must be ":basic'
      end

      @http_debug = @options[:http_debug]

      @options.freeze

      @cache = OpenStruct.new
    end

    def Feature # :nodoc:
      ProductBoard::Resource::FeatureFactory.new(self)
    end

    def Version # :nodoc:
      ProductBoard::Resource::VersionFactory.new(self)
    end

    # HTTP methods without a body
    def delete(path, headers = {})
      request(:delete, path, nil, merge_default_headers(headers))
    end

    def get(path, headers = {})
      request(:get, path, nil, merge_default_headers(headers))
    end

    def head(path, headers = {})
      request(:head, path, nil, merge_default_headers(headers))
    end

    # HTTP methods with a body
    def post(path, body = '', headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      request(:post, path, body, merge_default_headers(headers))
    end

    def post_multipart(path, file, headers = {})
      puts "post multipart: #{path} - [#{file}]" if @http_debug
      @request_client.request_multipart(path, file, headers)
    end

    def put(path, body = '', headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      request(:put, path, body, merge_default_headers(headers))
    end

    # Sends the specified HTTP request to the REST API through the
    # appropriate method (oauth, basic).
    def request(http_method, path, body = '', headers = {})
      puts "#{http_method}: #{path} - [#{body}]" if @http_debug
      @request_client.request(http_method, path, body, headers)
    end

    # Stops sensitive client information from being displayed in logs
    def inspect
      "#<ProductBoard::Client:#{object_id}>"
    end

    protected

    def merge_default_headers(headers)
      { 'Accept' => 'application/json' }.merge(@options[:default_headers]).merge(headers)
    end
  end
end
