module Elastics
  module ActiveRecord
    module TasksConfig
      def base_paths
        @base_paths ||= if defined?(Rails)
          [File.join(Rails.root, 'db', 'elastics')]
        else
          super
        end
      end

      def client
        @client ||= ::ActiveRecord::Base.elastics
      end

      def version_manager
        @version_manager ||= ::ActiveRecord::Base.elastics_version_manager
      end

      def config
        @config ||= ::ActiveRecord::Base.elastics_config
      end
    end
  end
end
