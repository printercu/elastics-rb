module Elastics
  module ActiveRecord
    extend ActiveSupport::Autoload

    autoload :SearchResult
    autoload :ModelSchema
    autoload :HelperMethods

    class << self
      def install
        ::ActiveRecord::Base.extend self
        Instrumentation::ActiveSupport.install
      end
    end

    include Model::Connection

    def elastics_config
      @elastics_config ||= connection_config[:elastics].try!(:with_indifferent_access) ||
        raise('No elastics configuration in database.yml')
    end

    def indexed_with_elastics(options = {})
      options = {
        hooks: [:update, :destroy],
      }.merge!(options)

      extend ModelSchema
      include HelperMethods
      extend Model::Tracking

      self.elastics_index_base  = options[:index] if options[:index]
      self.elastics_type_name   = options[:type]  if options[:type]

      install_elastics_hooks(options[:hooks])
    end

    private
      def install_elastics_hooks(hooks)
        if hooks.include?(:update)
          after_commit :index_elastics,
            on:     [:create, :update],
            unless: :skip_elastics?,
            if:     -> { previous_changes.any? }
        end
        if hooks.include?(:destroy)
          after_commit :delete_elastics, on: [:destroy], unless: :skip_elastics?
        end
      end
  end
end
