module Elastics
  module ActiveRecord
    class SearchResult < Result::Search
      def initialize(response, options = {})
        @model = options[:model]
        super response, options
      end

      # super.map(&:to_i)
      def ids
        @ids ||= hits['hits'.freeze].map { |x| x['_id'.freeze].to_i }
      end

      def collection
        @collection ||= @model.find_all_ordered ids_to_find
      end

      def relation
        @model.where(id: ids_to_find)
      end
    end
  end
end
