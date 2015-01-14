module Elastics
  module Model
    module HelperMethods
      def self.included(base)
        base.class_eval do
          extend ClassMethods

          # don't override to_elastics method, if it already exists
          if !instance_methods.include?(:to_elastics) && instance_methods.include?(:as_json)
            alias_method :to_elastics, :as_json
          end
        end
      end

      module ClassMethods
        def elastics_params
          {
            index:  elastics_index_name,
            type:   elastics_type_name,
            model:  self,
          }
        end

        # Proxies #request method to elastics client with specified index & type.
        def request_elastics(params)
          elastics.request(elastics_params.merge!(params))
        end

        # Proxies #bulk method to elastics client with specified index & type.
        def bulk_elastics(params = {}, &block)
          elastics.bulk(elastics_params.merge!(params), &block)
        end

        # Performs `_search` request on type and instantiates result object.
        # Result::Search is a default result class. It can be overriden with
        # :result_class option.
        def search_elastics(data = {}, options = {})
          request = {
            id:     :_search,
            body:   data,
          }
          if routing = options[:routing]
            request[:query] = {routing: routing}
          end
          result_class = options[:result_class] || Result::Search
          result_class.new request_elastics(request), options
        end

        # Performs `_refresh` request on index.
        def refresh_elastics
          request_elastics(method: :post, type: nil, id: :_refresh)
        end

        # Indexes given records using batch API.
        def index_batch_elastics(batch)
          bulk_elastics do |bulk|
            batch.each do |record|
              bulk.index record.id, record.to_elastics
            end
          end
        end

        # Reindexes all records. It requires #find_in_batches method to be defined.
        def reindex_elastics(options = {})
          find_in_batches(options) do |batch|
            index_batch_elastics(batch)
          end
        end

        # Deletes all records in type keeping its mapping using "Delete by query" API.
        def clear_elastics
          request_elastics method: :delete, id: :_query, body: {query: {match_all: {}}}
        end

        def elastics_mapping
          request_elastics(id: :_mapping)
        end
      end

      def index_elastics
        self.class.request_elastics(method: :post, id: id, body: to_elastics)
      end

      def update_elastics(data)
        self.class.request_elastics(method: :post, id: "#{id}/_update", body: data)
      end

      def update_elastics_doc(fields)
        update_elastics(doc: fields)
      end

      def delete_elastics
        self.class.request_elastics(method: :delete, id: id)
      rescue NotFound
      end
    end
  end
end
