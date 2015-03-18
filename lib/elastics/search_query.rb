module Elastics
  # Helpers to build search query.
  #
  #     class Query
  #       include Elastics::SearchQuery
  #
  #       # implement any of:
  #       #   query, phrase_query, query_filters, post_filter, aggregations
  #
  #       def phrase_query
  #         {bool: {should: [
  #           {multi_match: {
  #             # ...
  #           }}
  #         ]}}
  #         # or just
  #         {math: {message: params[:query_string]}}
  #       end
  #
  #       def query_filters
  #         [
  #           {term: {published: true}},
  #           terms_array_query(:tag, @params[:tags], execution: :and),
  #           some_complex_filter,
  #         ]
  #       end
  #
  #       def aggregations
  #         {
  #           tag: {terms: {
  #             field:      :tag,
  #             size:       10,
  #             shard_size: 10,
  #           }},
  #         }
  #       end
  #     end
  #
  #     result = Model.search_elastics Query.new(params).as_json
  module SearchQuery
    include Elastics::QueryHelper

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def as_json
      page = params[:page] || 1
      per_page = params[:per_page] || 10
      result = {
        from:         (page - 1) * per_page,
        size:         per_page,
        fields:       [],
        query:        query,
        sort:         sort,
      }
      post_filter = self.post_filter
      result[:post_filter] = post_filter if post_filter
      aggregations = self.aggregations
      result[:aggregations] = aggregations if aggregations
      result
    end

    # Builds query from phrase_query & query_filters.
    def query
      normalize_query(phrase_query, query_filters.compact)
    end

    def phrase_query
    end

    def query_filters
      []
    end

    def post_filter
    end

    def aggregations
    end

    # Takes `params[:sort]` and returns it compatible with elastics.
    # Wraps scalars into array, hashes are converted into arrays,
    # array are passed as is.
    #
    #     {name: :asc, _score: :desc} => [{name: :asc}, {_score: :desc}]
    #     :created_at => [:created_at]
    def sort
      val = params[:sort]
      case val
      when Hash   then val.map { |x| Hash[[x]] }
      when Array  then val
      else val ? [val] : []
      end || []
    end
  end
end
