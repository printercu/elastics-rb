module Elastics
  module ActiveRecord
    module HelperMethods
      extend ActiveSupport::Concern

      module ClassMethods
        def search(data)
          es_results = search_elastics(data).with_indifferent_access
          ids = es_results[:hits][:hits].map { |x| x[:_id].to_i }
          relation = where(id: ids)
          items_by_id = relation.index_by(&:id)
          collection = ids.map { |i| items_by_id[i] }
          {
            collection: collection,
            relation: relation,
            search: es_results,
          }
        end

        def search_elastics(data)
          request_elastics(id: :_search, data: data)
        end

        def request_elastics(params)
          elastics.request(params.merge(
            index:  elastics_index_name,
            type:   elastics_type_name,
          ))
        end

        def elastics_mapping
          request_elastics(method: :get, id: :_mapping)
        end
      end

      def index_elastics
        self.class.request_elastics(method: :post, id: id, data: to_elastics)
      end

      def delete_elastics
        self.class.request_elastics(method: :delete, id: id)
      end

      def to_elastics
        as_json
      end
    end
  end
end
