module Elastics
  module QueryHelper
    def normalize_filters(filters)
      return filters unless filters.is_a?(Array)
      return filters[0] if 2 > filters.size
      {and: {filters: filters}}
    end

    def normalize_query(query, filters)
      filter = normalize_filters filters
      query ||= {match_all: {}}
      return query unless filter
      {filtered: {
        query:  query,
        filter: filter,
      }}
    end

    def terms_query(field, val, options = {})
      if val.is_a?(Array)
        {terms: {field => val}.merge(options)}
      else
        result = {term: {field => val}}
      end
    end
  end
end
