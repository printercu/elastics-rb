module Elastics
  class Error < StandardError; end
  class NotFound < Error; end

  require 'elastics/client'
  require 'elastics/query_helper'

  autoload :Tasks, 'elastics/tasks'

  extend QueryHelper
end

require 'elastics/railtie' if defined?(Rails)
