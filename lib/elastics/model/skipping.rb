module Elastics
  module Model
    module Skipping
      class << self
        def models
          Thread.current[:elastics_skip_models] ||= {}
        end

        def included(base)
          base.extend self
          base.extend ClassMethods
          base.send :include, InstanceMethods
        end
      end

      def skip_elastics
        self.skip_elastics = true
        yield
      ensure
        self.skip_elastics = false
      end

      module ClassMethods
        def skip_elastics?
          Skipping.models[self]
        end

        def skip_elastics=(val)
          Skipping.models[self] = val
        end
      end

      module InstanceMethods
        attr_writer :skip_elastics

        def skip_elastics?
          @skip_elastics || self.class.skip_elastics?
        end
      end
    end
  end
end
