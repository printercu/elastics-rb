module Elastics
  module ActiveRecord
    module HelperMethods
      extend ActiveSupport::Concern

      module ClassMethods
        def request_elastics(params)
          request = {
            index:  elastics_index_name,
            type:   elastics_type_name,
          }.merge!(params)
          elastics.request(request)
        end

        def search_elastics(data = {}, options = {})
          request = {
            id:   :_search,
            data: data,
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

        def reindex_elastics(*args)
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
