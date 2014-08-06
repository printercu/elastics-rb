module Elastics
  module ActiveRecord
    extend ActiveSupport::Autoload

    autoload :ModelSchema
    autoload :HelperMethods
    autoload :Instrumentation
    autoload :LogSubscriber

    def elastics_config
      @elastics_config ||= connection_config[:elastics].try!(:with_indifferent_access) ||
        raise('No elastics configuration in database.yml')
    end

    def elastics
      @elastics ||= Client.new elastics_config.slice(:host, :port)
    end

    def indexed_with_elastics(options = {})
      options = {
        hooks: [:update, :destroy],
      }.merge(options)

      extend ModelSchema
      include HelperMethods
      extend Instrumentation

      self.elastics_index_name  = options[:index] if options[:index]
      self.elastics_type_name   = options[:type]  if options[:type]

      hooks = options[:hooks]
      after_commit :index_elastics, on: [:create, :update] if hooks.include?(:update)
      after_commit :delete_elastics, on: [:destroy] if hooks.include?(:destroy)
    end
  end
end
