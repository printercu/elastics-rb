module Elastics
  module ActiveRecord
    module ModelSchema
      class << self
        def track_model(model)
          Elastics.models << model unless model.abstract_class?
        end

        def extended(base)
          track_model(base)
        end
      end

      attr_writer :elastics_index_base, :elastics_type_name

      def elastics_index_name
        reset_elastics_index_name unless defined?(@elastics_index_name)
        @elastics_index_name
      end

      def elastics_type_name
        @elastics_type_name ||= model_name.to_s.demodulize.underscore.singularize
      end

      def reset_elastics_index_name
        @elastics_index_name = if self != ::ActiveRecord::Base && !abstract_class?
          superclass.try(:elastics_index_name) || compute_elastics_index_name
        end
      end

      def compute_elastics_index_name
        elastics_version_manager.index_name(elastics_index_base)
      end

      def elastics_index_base
        @elastics_index_base || elastics_config[:index] || elastics_type_name
      end

      def inherited(base)
        super.tap { ::Elastics::ActiveRecord::ModelSchema.track_model(base) }
      end
    end
  end
end
