require 'active_support/core_ext/string'
require 'active_support/inflector'
require 'set'

module ProductBoard
  # This class provides the base object and REST mapping for all the ProductBoard resource
  # subclasses and actions available for each resource.  For now, resource actions only
  # support a read-only modality.
  #
  # ++ Fetching all resources
  #
  #    client.Resource.all
  #
  # ++ Fetching a single resource
  #
  #    client.Resource.find(id)
  #
  # ++ Fetching a specific set of resources
  #
  #    client.Resource.find_by(params)
  #
  class Base
    QUERY_PARAMS_FOR_SINGLE_FETCH = Set.new %i[expand fields]
    QUERY_PARAMS_FOR_SEARCH = Set.new %i[expand fields startAt maxResults]

    # A reference to the ProductBoard::Client used to initialize this resource.
    attr_reader :client

    # Returns true if this instance has been fetched from the server
    attr_accessor :expanded

    # Returns true if this instance has been deleted from the server
    attr_accessor :deleted

    # The hash of attributes belonging to this instance.  An exact
    # representation of the JSON returned from the ProductBoard API
    attr_accessor :attrs

    alias expanded? expanded
    alias deleted? deleted

    def initialize(client, options = {})
      @client   = client
      @attrs    = options[:attrs] || {}
      @expanded = options[:expanded] || false
      @deleted  = false

      # If this class has any belongs_to relationships, a value for
      # each of them must be passed in to the initializer.
      self.class.belongs_to_relationships.each do |relation|
        if options[relation]
          instance_variable_set("@#{relation}", options[relation])
          instance_variable_set("@#{relation}_id", options[relation].key_value)
        elsif options["#{relation}_id".to_sym]
          instance_variable_set("@#{relation}_id", options["#{relation}_id".to_sym])
        else
          raise ArgumentError, "Required option #{relation.inspect} missing" unless options[relation]
        end
      end
    end

    # The class methods are never called directly, they are always
    # invoked from a BaseFactory subclass instance.
    def self.all(client, options = {})
      response = client.get(collection_path(client))
      json = parse_json(response.body)
      json = json[endpoint_name.pluralize] if collection_attributes_are_nested
      json.map do |attrs|
        new(client, { attrs: attrs }.merge(options))
      end
    end

    # Finds and retrieves a resource with the given ID.
    def self.find(client, key, options = {})
      instance = new(client, options)
      instance.attrs[key_attribute.to_s] = key
      instance.fetch(false, query_params_for_single_fetch(options))
      instance
    end

    # Builds a new instance of the resource with the given attributes.
    # These attributes will be posted to the JIRA Api if save is called.
    def self.build(client, attrs)
      new(client, attrs: attrs)
    end

    # Returns the name of this resource for use in URL components.
    # E.g.
    #   JIRA::Resource::Issue.endpoint_name
    #     # => issue
    def self.endpoint_name
      name.split('::').last.downcase
    end

    # Returns the full path for a collection of this resource.
    # E.g.
    #   JIRA::Resource::Issue.collection_path
    #     # => /jira/rest/api/2/issue
    def self.collection_path(client, prefix = '/')
      client.options[:rest_base_path] + prefix + endpoint_name
    end

    # Returns the singular path for the resource with the given key.
    # E.g.
    #   JIRA::Resource::Issue.singular_path('123')
    #     # => /jira/rest/api/2/issue/123
    #
    # If a prefix parameter is provided it will be injected between the base
    # path and the endpoint.
    # E.g.
    #   JIRA::Resource::Comment.singular_path('456','/issue/123/')
    #     # => /jira/rest/api/2/issue/123/comment/456
    def self.singular_path(client, key, prefix = '/')
      collection_path(client, prefix) + '/' + key
    end

    # Returns the attribute name of the attribute used for find.
    # Defaults to :id unless overridden.
    def self.key_attribute
      :id
    end

    def self.parse_json(string) # :nodoc:
      JSON.parse(string)
    end
  end
end