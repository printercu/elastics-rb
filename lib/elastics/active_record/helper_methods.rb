module Elastics
  module ActiveRecord
    module HelperMethods
      extend ActiveSupport::Concern

      module ClassMethods
        def search(data = {}, routing = nil)
          es_results = search_elastics(data, routing)
          ids = es_results['hits'.freeze]['hits'.freeze].map { |x| x['_id'.freeze].to_i }
          relation = where(id: ids)
          items_by_id = relation.index_by(&:id)
          collection = ids.map { |i| items_by_id[i] }
          {
            collection: collection,
            relation: relation,
            search: es_results,
          }
        end

        def search_elastics(data = {}, routing = nil)
          request = {
            id: :_search,
            data: data,
          }
          request[:query] = {routing: routing} if routing
          request_elastics(request)
        end

        def request_elastics(params)
          request = {
            index:  elastics_index_name,
            type:   elastics_type_name,
          }.merge!(params)
          elastics.request(request)
        end

        def elastics_mapping
          request_elastics(method: :get, id: :_mapping)
        end

        def reindex(*args)
          find_each(*args, &:index_elastics)
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
