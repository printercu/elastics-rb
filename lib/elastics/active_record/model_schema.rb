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

      attr_writer :elastics_index_name, :elastics_type_name

      def elastics_index_name
        reset_elastics_index_name unless defined?(@elastics_index_name)
        @elastics_index_name
      end

      def elastics_type_name
        reset_elastics_index_name unless defined?(@elastics_type_name)
        @elastics_type_name
      end

      def reset_elastics_index_name
        superclass_responds = superclass.respond_to?(:elastics_index_name)
        index = if abstract_class? && superclass_responds
          superclass == ::ActiveRecord::Base ? nil : superclass.elastics_index_name
        elsif superclass.abstract_class? && superclass_responds
          superclass.elastics_index_name || compute_elastics_index_name
        else
          compute_elastics_index_name
        end
        @elastics_index_name = index
        @elastics_type_name = compute_elastics_type_name
      end

      def compute_elastics_index_name(name = nil)
        elastics_config[:index] ||
          "#{elastics_config[:index_prefix]}#{name || table_name.singularize}"
      end

      def compute_elastics_type_name
        model_name.to_s.demodulize.underscore.singularize
      end

      def inherited(base)
        super.tap { ::Elastics::ActiveRecord::ModelSchema.track_model(base) }
      end
    end
  end
end
