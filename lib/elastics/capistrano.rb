Capistrano::Configuration.instance.load do
  namespace :elastics do
    %w(create drop migrate reindex).each do |method|
      desc "rake elastics:#{method}"
      task method, roles: :elastics, only: {primary: true} do
        bundle_cmd = fetch(:bundle_cmd, 'bundle')
        env = fetch(:rack_env, fetch(:rails_env, 'production'))
        run "cd #{current_path} && " \
          "#{bundle_cmd} exec rake elastics:#{method}[#{ENV['INDICES']}] #{ENV['ES_OPTIONS']} " \
          "RAILS_ENV=#{env}"
      end
    end
  end
end
