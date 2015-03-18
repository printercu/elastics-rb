module Elastics
  class Error < StandardError; end
  class NotFound < Error; end

  require 'elastics/client'

  autoload :AutoRefresh,      'elastics/auto_refresh'
  autoload :Instrumentation,  'elastics/instrumentation'
  autoload :Model,            'elastics/model'
  autoload :QueryHelper,      'elastics/query_helper'
  autoload :SearchQuery,      'elastics/search_query'
  autoload :Result,           'elastics/result'
  autoload :Tasks,            'elastics/tasks'
  autoload :VersionManager,   'elastics/version_manager'
end

require 'elastics/railtie' if defined?(Rails)
