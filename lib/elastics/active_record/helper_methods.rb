module Elastics
  module ActiveRecord
    module HelperMethods
      extend ActiveSupport::Concern

      def self.append_features(base)
        base.send :include, Model::HelperMethods
        base.send :include, Model::Skipping
        super
      end

      module ClassMethods
        # Performs `_search` request on type and instantiates result object.
        # SearchResult is a default result class. It can be overriden with
        # :result_class option.
        def search_elastics(data = {}, options = {})
          options[:result_class] ||= SearchResult
          options[:model] = self
          super
        end

        # Finds items by ids and returns array in the order in which ids were given.
        # Every missing record is replaced with `nil` in the result.
        # If `conditions_present` is `true` it doesn't add where clause.
        def find_all_ordered(ids, conditions_present = false)
          relation = conditions_present ? where(id: ids) : self
          items_by_id = relation.index_by(&:id)
          ids.map { |i| items_by_id[i] }
        end

        # Indexes all records in current scope.
        def index_all_elastics(*args)
          find_in_batches(*args) do |batch|
            index_batch_elastics(batch)
          end
        end

        # Reindexes records with `#index_all_elastics`. If model has scope
        # named `reindex_scope`, this method will apply it.
        #
        # Also supports `:updated_after` option to reindex only updated records.
        # Nothing is performed when `:updated_after` is set but model
        # has not `updated_at` column.
        def reindex_elastics(options = {})
          scope = respond_to?(:reindex_scope) ? reindex_scope : all
          if after = options.delete(:updated_after)
            if updated_at = arel_table[:updated_at]
              scope = scope.where(updated_at.gt(after))
            else
              return
            end
          end
          scope.index_all_elastics(options)
        end
      end
    end
  end
end
