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

        def request_elastics(params)
          elastics.request(elastics_params.merge!(params))
        end

        def bulk_elastics(params = {}, &block)
          elastics.bulk(elastics_params.merge!(params), &block)
        end

        def refresh_elastics
          request_elastics(method: :post, type: nil, id: :_refresh)
        end

        def index_batch_elastics(batch)
          bulk_elastics do |bulk|
            batch.each do |record|
              bulk.index record.id, record.to_elastics
            end
          end
        end

        def reindex_elastics(options = {})
          raise 'Not implemented'
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
