require 'forwardable'

module ProductBoard
  # This class provides a reusable component for handling HTTP errors.
  class HTTPError < StandardError
    extend Forwardable

    def_instance_delegators :@response, :code
    attr_reader :response, :message

    def initialize(response)
      @response = response
      @message = response.try(:message).presence || response.try(:body)
    end
  end
end
