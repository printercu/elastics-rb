module Elastics
  module ActiveRecord
    module ModelSchema
      include Model::Schema

      def elastics_type_name
        @elastics_type_name ||= model_name.to_s.demodulize.underscore.singularize
      end

      def reset_elastics_index_name
        @elastics_index_name = if self != ::ActiveRecord::Base && !abstract_class?
          superclass.try(:elastics_index_name) || compute_elastics_index_name
        end
      end

      def track_elastics_model?
        !abstract_class?
      end
    end
  end
end
