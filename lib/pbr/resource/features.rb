module ProductBoard
  module Resource
    class FeaturesFactory < ProductBoard::BaseFactory # :nodoc:
    end

    class Features < ProductBoard::Base
      def self.key_attribute
        :key
      end
    end
  end
end