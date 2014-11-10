module Elastics
  module Result
    class Search
      attr_reader :response

      def initialize(response, options = {})
        @response = response
        @options = options
      end

      def hits
        @hits ||= @response['hits'.freeze]
      end

      def ids
        @ids ||= hits['hits'.freeze].map { |x| x['_id'.freeze] }
      end

      # Allows to split ids into two parts, if you want to fetch from primary DB
      # less then was found. This method returns the first part,
      # `rest_ids` - the second.
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

      def aggregations
        @aggregations ||= @response['aggregations'.freeze]
      end

      def total
        hits['total'.freeze]
      end
    end
  end
end
