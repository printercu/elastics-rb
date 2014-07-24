require 'elastics/active_record'

module Elastics
  class Railtie < Rails::Railtie
    initializer 'elastics.configure_rails_initialization' do
      ::ActiveRecord::Base.extend Elastics::ActiveRecord
    end

    rake_tasks do
      load 'tasks/elastics.rake'
    end
  end
end

Elastics::Railtie.run_initializers
