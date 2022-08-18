module ProductBoard
  module Resource
    class FeatureFactory < ProductBoard::BaseFactory # :nodoc:
    end

    class Feature < ProductBoard::Base
      def self.key_attribute
        :key
      end
    end
  end
end