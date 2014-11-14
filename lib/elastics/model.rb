module Elastics
  module Model
    autoload :Connection,     'elastics/model/connection'
    autoload :HelperMethods,  'elastics/model/helper_methods'
    autoload :Schema,         'elastics/model/schema'
    autoload :Skipping,       'elastics/model/skipping'

    require 'elastics/model/tracking'

    def self.included(base)
      base.extend Connection
      base.extend Schema
      base.extend Tracking
      base.send :include, HelperMethods
      base.send :include, Skipping
    end
  end
end
