module Elastics
  class Error < StandardError; end
  class NotFound < Error; end

  require 'elastics/client'
  require 'elastics/query_helper'

  autoload :Tasks, 'elastics/tasks'

  extend QueryHelper

  class << self
    attr_reader :models

    def reset_models
      @models = []
    end
  end

  reset_models
end

require 'elastics/railtie' if defined?(Rails)
