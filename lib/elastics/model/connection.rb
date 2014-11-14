module Elastics
  module Model
    module Connection
      attr_accessor :elastics_config

      def elastics
        @elastics ||= Client.new elastics_config.slice(:host)
      end

      # Don't memoize to GC it after initialization
      def elastics_version_manager
        VersionManager.new(elastics, elastics_config.slice(
          :service_index,
          :index_prefix,
        ))
      end
    end
  end
end
