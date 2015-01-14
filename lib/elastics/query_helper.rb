module Elastics
  module QueryHelper
    # Combines multiple filters into `and` filter. Returns unmodified input
    # unless it was an array.
    def normalize_filters(filters)
      return filters unless filters.is_a?(Array)
      return filters[0] if 2 > filters.size
      {and: {filters: filters}}
    end

    # Wraps given query into `filtered` query if filter is present.
    # Also replaces empty query with `match_all`.
    def normalize_query(query, filters)
      filter = normalize_filters filters
      query ||= {match_all: {}}
      return query unless filter
      {filtered: {
        query:  query,
        filter: filter,
      }}
    end

    # Returns `term`(for scalar value) or `terms` (for array) query node
    # for specified field.
    def terms_query(field, val, options = {})
      if val.is_a?(Array)
        {terms: {field => val}.merge(options)}
      else
        {term: {field => val}}
      end
    end

    # Returns `nil` if falsy value or empty array is given. Other way
    # it returns term(s) query for it.
    def terms_array_query(field, val, options = {})
      terms_query(field, val, options) if val && (!val.is_a?(Array) || val.any?)
    end
  end
end
