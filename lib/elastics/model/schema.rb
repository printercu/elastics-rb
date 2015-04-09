module Elastics
  module Model
    module Schema
      attr_writer :elastics_index_base, :elastics_type_name

      def elastics_index_name
        reset_elastics_index_name unless defined?(@elastics_index_name)
        @elastics_index_name
      end

      def elastics_type_name
        @elastics_type_name ||= name.split('::').last.downcase
      end

      def reset_elastics_index_name
        @elastics_index_name =
          if respond_to?(:superclass) && superclass.respond_to?(:elastics_index_name)
            superclass.elastics_index_name
          else
            compute_elastics_index_name
          end
      end

      def compute_elastics_index_name
        elastics_version_manager.index_name(elastics_index_base)
      end

      def elastics_index_base
        @elastics_index_base || elastics_config[:index] || elastics_type_name
      end
    end
  end
end
