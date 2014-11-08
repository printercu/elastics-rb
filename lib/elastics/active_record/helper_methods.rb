module Elastics
  module ActiveRecord
    module HelperMethods
      extend ActiveSupport::Concern

      included do
        alias_method :to_elastics, :as_json unless instance_methods.include?(:to_elastics)
      end

      module ClassMethods
        def request_elastics(params)
          request = {
            index:  elastics_index_name,
            type:   elastics_type_name,
            model:  self,
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

        def refresh_elastics
          request_elastics(method: :post, type: nil, id: :_refresh)
        end
      end

      def index_elastics
        self.class.request_elastics(method: :post, id: id, data: to_elastics)
      end

      def update_elastics(fields)
        self.class.request_elastics(method: :post, id: "#{id}/_update", data: {
          doc: fields
        })
      end

      def delete_elastics
        self.class.request_elastics(method: :delete, id: id)
      end
    end
  end
end
