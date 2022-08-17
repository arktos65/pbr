require 'active_support/core_ext/string'
require 'active_support/inflector'
require 'set'

module ProductBoard
  # This class provides the foundational object and REST mapping for all ProductBoard::Resource
  # subclasses and actions.  Read-only resource access is the only supported modality at this time.
  #
  # ++ Fetching all resources
  #
  #    client.Resource.all
  #
  # ++ Fetching a single resource
  #
  #    client.Resource.find(id)
  #
  # ++ Fetching a set of resources
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
    # These attributes will be posted to the ProductBoard API if save is called.
    def self.build(client, attrs)
      new(client, attrs: attrs)
    end

    # Returns the name of this resource for use in URL components.
    # E.g.
    #   ProductBoard::Resource::Issue.endpoint_name
    #     # => issue
    def self.endpoint_name
      name.split('::').last.downcase
    end

    # Returns the full path for a collection of this resource.
    # E.g.
    #   ProductBoard::Resource::feature.collection_path
    #     # => /jira/rest/api/2/issue
    def self.collection_path(client, prefix = '/')
      client.options[:rest_base_path] + prefix + endpoint_name
    end

    # Returns the singular path for the resource with the given key.
    # E.g.
    #   ProductBoard::Resource::Feature.singular_path('123')
    #     # => /jira/rest/api/2/issue/123
    #
    # If a prefix parameter is provided it will be injected between the base
    # path and the endpoint.
    # E.g.
    #   ProductBoard::Resource::Comment.singular_path('456','/issue/123/')
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

    # Declares that this class contains a singular instance of another resource
    # within the JSON returned from the ProductBoard API.
    #
    #   class Example < ProductBoard::Base
    #     has_one :child
    #   end
    #
    #   example = client.Example.find(1)
    #   example.child # Returns a ProductBoard::Resource::Child
    #
    # The following options can be used to override the default behaviour of the
    # relationship:
    #
    # [:attribute_key]  The relationship will by default reference a JSON key on the
    #                   object with the same name as the relationship.
    #
    #                     has_one :child # => {"id":"123",{"child":{"id":"456"}}}
    #
    #                   Use this option if the key in the JSON is named differently.
    #
    #                     # Respond to resource.child, but return the value of resource.attrs['kid']
    #                     has_one :child, :attribute_key => 'kid' # => {"id":"123",{"kid":{"id":"456"}}}
    #
    # [:class]          The class of the child instance will be inferred from the name of the
    #                   relationship. E.g. <tt>has_one :child</tt> will return a <tt>ProductBoard::Resource::Child</tt>.
    #                   Use this option to override the inferred class.
    #
    #                     has_one :child, :class => ProductBoard::Resource::Kid
    # [:nested_under]   In some cases, the JSON return from ProductBoard is nested deeply for particular
    #                   relationships.  This option allows the nesting to be specified.
    #
    #                     # Specify a single depth of nesting.
    #                     has_one :child, :nested_under => 'foo'
    #                       # => Looks for {"foo":{"child":{}}}
    #                     # Specify deeply nested JSON
    #                     has_one :child, :nested_under => ['foo', 'bar', 'baz']
    #                       # => Looks for {"foo":{"bar":{"baz":{"child":{}}}}}
    def self.has_one(resource, options = {})
      attribute_key = options[:attribute_key] || resource.to_s
      child_class = options[:class] || ('ProductBoard::Resource::' + resource.to_s.classify).constantize
      define_method(resource) do
        attribute = maybe_nested_attribute(attribute_key, options[:nested_under])
        return nil unless attribute
        child_class.new(client, attrs: attribute)
      end
    end

    # Declares that this class contains a collection of another resource
    # within the JSON returned from the ProductBoard API.
    #
    #   class Example < ProductBoard::Base
    #     has_many :children
    #   end
    #
    #   example = client.Example.find(1)
    #   example.children # Returns an instance of Jira::Resource::HasManyProxy,
    #                    # which behaves exactly like an array of
    #                    # Jira::Resource::Child
    #
    # The following options can be used to override the default behaviour of the
    # relationship:
    #
    # [:attribute_key]  The relationship will by default reference a JSON key on the
    #                   object with the same name as the relationship.
    #
    #                     has_many :children # => {"id":"123",{"children":[{"id":"456"},{"id":"789"}]}}
    #
    #                   Use this option if the key in the JSON is named differently.
    #
    #                     # Respond to resource.children, but return the value of resource.attrs['kids']
    #                     has_many :children, :attribute_key => 'kids' # => {"id":"123",{"kids":[{"id":"456"},{"id":"789"}]}}
    #
    # [:class]          The class of the child instance will be inferred from the name of the
    #                   relationship. E.g. <tt>has_many :children</tt> will return an instance
    #                   of <tt>ProductBoard::Resource::HasManyProxy</tt> containing the collection of
    #                   <tt>ProductBoard::Resource::Child</tt>.
    #                   Use this option to override the inferred class.
    #
    #                     has_many :children, :class => ProductBoard::Resource::Kid
    # [:nested_under]   In some cases, the JSON return from ProductBoard is nested deeply for particular
    #                   relationships.  This option allows the nesting to be specified.
    #
    #                     # Specify a single depth of nesting.
    #                     has_many :children, :nested_under => 'foo'
    #                       # => Looks for {"foo":{"children":{}}}
    #                     # Specify deeply nested JSON
    #                     has_many :children, :nested_under => ['foo', 'bar', 'baz']
    #                       # => Looks for {"foo":{"bar":{"baz":{"children":{}}}}}
    def self.has_many(collection, options = {})
      attribute_key = options[:attribute_key] || collection.to_s
      child_class = options[:class] || ('ProductBoard::Resource::' + collection.to_s.classify).constantize
      self_class_basename = name.split('::').last.downcase.to_sym
      define_method(collection) do
        child_class_options = { self_class_basename => self }
        attribute = maybe_nested_attribute(attribute_key, options[:nested_under]) || []
        collection = attribute.map do |child_attributes|
          child_class.new(client, child_class_options.merge(attrs: child_attributes))
        end
        HasManyProxy.new(self, child_class, collection)
      end
    end

    def self.belongs_to_relationships
      @belongs_to_relationships ||= []
    end

    def self.belongs_to(resource)
      belongs_to_relationships.push(resource)
      attr_reader resource
      attr_reader "#{resource}_id"
    end

    def self.collection_attributes_are_nested
      @collection_attributes_are_nested ||= false
    end

    def self.nested_collections(value)
      @collection_attributes_are_nested = value
    end

    def id
      attrs['id']
    end

    # Returns a symbol for the given instance, for example
    # ProductBoard::Resource::Issue returns :issue
    def to_sym
      self.class.endpoint_name.to_sym
    end

    # Checks if method_name is set in the attributes hash
    # and returns true when found, otherwise proxies the
    # call to the superclass.
    def respond_to?(method_name, _include_all = false)
      if attrs.key?(method_name.to_s)
        true
      else
        super(method_name)
      end
    end

    # Overrides method_missing to check the attribute hash
    # for resources matching method_name and proxies the call
    # to the superclass if no match is found.
    def method_missing(method_name, *_args)
      if attrs.key?(method_name.to_s)
        attrs[method_name.to_s]
      else
        super(method_name)
      end
    end

    # Each resource has a unique key attribute, this method returns the value
    # of that key for this instance.
    def key_value
      @attrs[self.class.key_attribute.to_s]
    end

    def collection_path(prefix = '/')
      # Just proxy this to the class method
      self.class.collection_path(client, prefix)
    end

    # This returns the URL path component that is specific to this instance,
    # for example for Issue id 123 it returns '/issue/123'.  For an unsaved
    # issue it returns '/issue'
    def path_component
      path_component = "/#{self.class.endpoint_name}"
      path_component += '/' + key_value if key_value
      path_component
    end

    # Fetches the attributes for the specified resource from ProductBoard unless
    # the resource is already expanded and the optional force reload flag
    # is not set
    def fetch(reload = false, query_params = {})
      return if expanded? && !reload
      response = client.get(url_with_query_params(url, query_params))
      set_attrs_from_response(response)
      @expanded = true
    end

    # Saves the specified resource attributes by sending either a POST or PUT
    # request to ProductBoard, depending on resource.new_record?
    #
    # Accepts an attributes hash of the values to be saved.  Will throw a
    # ProductBoard::HTTPError if the request fails (response is not HTTP 2xx).
    def save!(attrs, path = nil)
      path ||= new_record? ? url : patched_url
      http_method = new_record? ? :post : :put
      response = client.send(http_method, path, attrs.to_json)
      set_attrs(attrs, false)
      set_attrs_from_response(response)
      @expanded = false
      true
    end

    # Saves the specified resource attributes by sending either a POST or PUT
    # request to ProductBoard, depending on resource.new_record?
    #
    # Accepts an attributes hash of the values to be saved. Will return false
    # if the request fails.
    def save(attrs, path = url)
      begin
        save_status = save!(attrs, path)
      rescue ProductBoard::HTTPError => exception
        begin
          set_attrs_from_response(exception.response) # Merge error status generated by ProductBoard REST API
        rescue JSON::ParserError => parse_exception
          set_attrs('exception' => {
            'class' => exception.response.class.name,
            'code' => exception.response.code,
            'message' => exception.response.message
          })
        end
        # raise exception
        save_status = false
      end
      save_status
    end

    # Sets the attributes hash from a HTTPResponse object from ProductBoard if it is
    # not nil or is not a json response.
    def set_attrs_from_response(response)
      unless response.body.nil? || (response.body.length < 2)
        json = self.class.parse_json(response.body)
        set_attrs(json)
      end
    end

    # Set the current attributes from a hash.  If clobber is true, any existing
    # hash values will be clobbered by the new hash, otherwise the hash will
    # be deeply merged into attrs.  The target paramater is for internal use only
    # and should not be used.
    def set_attrs(hash, clobber = true, target = nil)
      target ||= @attrs
      if clobber
        target.merge!(hash)
        hash
      else
        hash.each do |k, v|
          if v.is_a?(Hash)
            set_attrs(v, clobber, target[k])
          else
            target[k] = v
          end
        end
      end
    end

    # Sends a delete request to the ProductBoard Api and sets the deleted instance
    # variable on the object to true.
    def delete
      client.delete(url)
      @deleted = true
    end

    def has_errors?
      respond_to?('errors')
    end

    def url
      prefix = '/'
      unless self.class.belongs_to_relationships.empty?
        prefix = self.class.belongs_to_relationships.inject(prefix) do |prefix_so_far, relationship|
          prefix_so_far.to_s + relationship.to_s + '/' + send("#{relationship}_id").to_s + '/'
        end
      end
      if @attrs['self']
        the_url = @attrs['self']
        the_url = the_url.sub(@client.options[:site].chomp('/'), '') if @client.options[:site]
        the_url
      elsif key_value
        self.class.singular_path(client, key_value.to_s, prefix)
      else
        self.class.collection_path(client, prefix)
      end
    end

    # This method fixes issue that there is no / prefix in url. It is happened when we call for instance
    # Looks like this issue is actual only in case if you use atlassian sdk your app path is not root (like /jira in example below)
    # issue.save() for existing resource.
    # As a result we got error 400 from ProductBoard API:
    # [07/Jun/2015:15:32:19 +0400] "PUT jira/rest/api/2/issue/10111 HTTP/1.1" 400 -
    # After applying this fix we have normal response:
    # [07/Jun/2015:15:17:18 +0400] "PUT /jira/rest/api/2/issue/10111 HTTP/1.1" 204 -
    def patched_url
      result = url
      return result if result.start_with?('/', 'http')
      "/#{result}"
    end

    def to_s
      "#<#{self.class.name}:#{object_id} @attrs=#{@attrs.inspect}>"
    end

    # Returns a JSON representation of the current attributes hash.
    def to_json(options = {})
      attrs.to_json(options)
    end

    # Determines if the resource is newly created by checking whether its
    # key_value is set. If it is nil, the record is new and the method
    # will return true.
    def new_record?
      key_value.nil?
    end

    protected

    # This allows conditional lookup of possibly nested attributes.  Example usage:
    #
    #   maybe_nested_attribute('foo')                 # => @attrs['foo']
    #   maybe_nested_attribute('foo', 'bar')          # => @attrs['bar']['foo']
    #   maybe_nested_attribute('foo', ['bar', 'baz']) # => @attrs['bar']['baz']['foo']
    #
    def maybe_nested_attribute(attribute_name, nested_under = nil)
      self.class.maybe_nested_attribute(@attrs, attribute_name, nested_under)
    end

    def self.maybe_nested_attribute(attributes, attribute_name, nested_under = nil)
      return attributes[attribute_name] if nested_under.nil?
      if nested_under.instance_of? Array
        final = nested_under.inject(attributes) do |parent, key|
          break if parent.nil?
          parent[key]
        end
        return nil if final.nil?
        final[attribute_name]
      else
        return attributes[nested_under][attribute_name]
      end
    end

    def url_with_query_params(url, query_params)
      self.class.url_with_query_params(url, query_params)
    end

    def self.url_with_query_params(url, query_params)
      if !query_params.empty?
        "#{url}?#{hash_to_query_string query_params}"
      else
        url
      end
    end

    def hash_to_query_string(query_params)
      self.class.hash_to_query_string(query_params)
    end

    def self.hash_to_query_string(query_params)
      query_params.map do |k, v|
        CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s)
      end.join('&')
    end

    def self.query_params_for_single_fetch(options)
      Hash[options.select do |k, _v|
        QUERY_PARAMS_FOR_SINGLE_FETCH.include? k
      end]
    end

    def self.query_params_for_search(options)
      Hash[options.select do |k, _v|
        QUERY_PARAMS_FOR_SEARCH.include? k
      end]
    end
  end
end
