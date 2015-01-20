module Elastics
  module ActiveRecord
    class SearchResult < Result::Search
      # It expects `:model` option with a model-class.
      # Optionally pass `scope` option with a lambda which takes and modifies
      # relation.
      def initialize(response, options = {})
        @model = options[:model]
        @scope = options[:scope]
        super response, options
      end

      # super.map(&:to_i)
      def ids
        @ids ||= hits['hits'.freeze].map { |x| x['_id'.freeze].to_i }
      end

      def collection
        @collection ||= relation.find_all_ordered(ids_to_find, true)
      end

      def relation
        @relation ||= begin
          result = @model.where(id: ids_to_find)
          @scope ? @scope.call(result) : result
        end
      end
    end
  end
end
