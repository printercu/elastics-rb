require 'active_support'
require 'active_support/core_ext'

module Elastics
  module Tasks
    require 'elastics/tasks/indices'
    include Indices

    require 'elastics/tasks/mappings'
    include Mappings

    extend self

    attr_writer :base_paths, :client, :config

    def base_paths
      @base_paths ||= [File.join(Rails.root, 'db', 'elastics')]
    end

    def migrate(options = {})
      delete_indices if options[:flush]
      create_indices
      put_mappings
    end

    def client
      @client ||= ::ActiveRecord::Base.elastics
    end

    def config
      @config ||= ::ActiveRecord::Base.elastics_config
    end

    def log(*args)
      Rails.logger.info(*args)
    end
  end
end
