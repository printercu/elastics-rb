namespace 'elastics' do
  task load_config: [:environment, 'db:load_config'] do
  end

  desc 'Creates indices and applies mappings (Use NOFLUSH to prevent old indices from deletion)'
  task migrate: :load_config do
    flush = !ENV.key?('NOFLUSH')
    Elastics::Tasks.migrate(flush: flush)
  end

  desc 'Creates indices'
  task create: :load_config do
    Elastics::Tasks.create_indices
  end

  desc 'Drops indices'
  task delete: :load_config do
    Elastics::Tasks.delete_indices
  end
end
