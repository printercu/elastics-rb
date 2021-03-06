namespace 'elastics' do
  task :load_config do |task, args|
    [:environment, 'db:load_config'].each do |dep|
      Rake::Task[dep].invoke if Rake::Task.task_defined?(dep)
    end
    @elastics_options = {
      version:  ENV['version'] || :current,
      reindex:  !ENV.key?('no_reindex'),
      drop:     !ENV.key?('no_drop'),
      types:    ENV['types'] && ENV['types'].split(',').map(&:strip),
      indices:  args.extras.empty? ? nil : args.extras
    }
    Elastics::Tasks.verbose = ENV.fetch('VERBOSE', 'true') == 'true'
  end

  desc 'Drop administrative index'
  task :purge, [:keep_data] => :load_config do |task, args|
    Elastics::Tasks.purge args[:keep_data]
  end

  desc 'Creates indices'
  task create: :load_config do
    Elastics::Tasks.create_indices @elastics_options
  end

  desc 'Drops indices'
  task drop: :load_config do
    Elastics::Tasks.drop_indices @elastics_options
  end

  desc 'Creates indices and applies mappings. Full migration when param is present'
  task migrate: :load_config do
    Elastics::Tasks.migrate @elastics_options
  end

  task migrate!: :load_config do
    Elastics::Tasks.migrate! @elastics_options
  end

  desc 'Reindex'
  task reindex: :load_config do
    Elastics::Tasks.reindex @elastics_options
  end
end
