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
        def search_elastics(data = {}, options = {})
          request = {
            id:   :_search,
            body: data,
          }
          if routing = options[:routing]
            request[:query] = {routing: routing}
          end
          SearchResult.new self, request_elastics(request), options
        end

        def find_all_ordered(ids)
          items_by_id = where(id: ids).index_by(&:id)
          ids.map { |i| items_by_id[i] }
        end

        def elastics_mapping
          request_elastics(method: :get, id: :_mapping)
        end

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
