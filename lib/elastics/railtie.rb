require 'elastics/active_record'

module Elastics
  class Railtie < Rails::Railtie
    initializer 'elastics.configure_rails_initialization' do
      ::ActiveRecord::Base.extend Elastics::ActiveRecord
      unless ::ActiveRecord::LogSubscriber < ActiveRecord::LogSubscriber
        ::ActiveRecord::LogSubscriber.send :include, ActiveRecord::LogSubscriber
      end
    end

    rake_tasks do
      load 'tasks/elastics.rake'
    end
  end
end
