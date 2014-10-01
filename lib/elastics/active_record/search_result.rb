module Elastics
  module ActiveRecord
    class SearchResult
      attr_reader :result

      def initialize(model, result, options = {})
        @model = model
        @result = result
        @options = options
      end

      def hits
        @hits ||= @result['hits'.freeze]
      end

      def ids
        @ids ||= hits['hits'.freeze].map { |x| x['_id'.freeze].to_i }
      end

      def ids_to_find
        @ids_to_find ||= begin
          limit = @options[:limit]
          limit ? ids[0...limit] : ids
        end
      end

      def rest_ids
        limit = @options[:limit]
        limit ? ids[limit..-1] : []
      end

      def collection
        @collection ||= @model.find_all_ordered ids_to_find
      end

      def relation
        @model.where id: ids_to_find
      end

      def aggregations
        @aggregations ||= @result['aggregations'.freeze]
      end

      def total
        hits['total'.freeze]
      end
    end
  end
end
