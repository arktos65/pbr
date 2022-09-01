module ProductBoard
  module Resource
    class ComponentsFactory < ProductBoard::BaseFactory # :nodoc:
    end

    class Components < ProductBoard::Base
      def self.key_attribute
        :key
      end
    end
  end
end