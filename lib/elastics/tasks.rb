require 'active_support'
require 'active_support/core_ext'

module Elastics
  module Tasks
    require 'elastics/tasks/indices'
    include Indices

    require 'elastics/tasks/mappings'
    include Mappings

    require 'elastics/tasks/migrations'
    include Migrations

    extend self

    attr_writer :base_paths

    def base_paths
      @base_paths ||= [File.join(Rails.root, 'db', 'elastics')]
    end

    def client
      @client ||= ::ActiveRecord::Base.elastics
    end

    def client=(val)
      @version_manager = nil
      @client = val
    end

    def version_manager
      @version_manager ||= ::ActiveRecord::Base.elastics_version_manager
    end

    def config
      @config ||= ::ActiveRecord::Base.elastics_config
    end

    def config=(val)
      @version_manager = nil
      @config = val
    end

    def log(*args)
      puts(*args)
    end

    private
      def each_filtered(collection, filter, &block)
        filter = filter && filter.map(&:to_s)
        collection = collection.select { |x| filter.include?(x) } if filter
        collection.each &block
      end
  end
end
