module Elastics
  module Tasks
    # Module contains basic configuration methods.
    # You should setup Elastics::Task yourself unless you you use ActiveRecord.
    module Config
      attr_writer :base_paths

      def base_paths
        @base_paths ||= Dir.pwd
      end

      def client
        @client ||= Client.new config.slice(:host, :port)
      end

      def client=(val)
        @version_manager = nil
        @client = val
      end

      def version_manager
        @version_manager ||= VersionManager.new(client, config.slice(
          :service_index,
          :index_prefix,
        ))
      end

      def config
        @config ||= {}
      end

      def config=(val)
        @version_manager = nil
        @config = val
      end
    end
  end
end
