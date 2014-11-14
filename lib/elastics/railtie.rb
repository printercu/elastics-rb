require 'elastics/active_record'

module Elastics
  class Railtie < Rails::Railtie
    initializer 'elastics.configure_rails_initialization' do
      ActiveRecord.install
    end

    rake_tasks do
      load 'tasks/elastics.rake'
    end

    config.to_prepare do
      Model.reset_list
    end
  end
end
