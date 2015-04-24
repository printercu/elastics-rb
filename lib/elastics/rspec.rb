module Elastics
  module RSpec
    module_function

    # Adds around filter to perform elastics specific helper actions.
    #
    #     - Enables autorefresh for each example,
    #     - Executes `clear_elastics` before each example,
    #     - Performs migration (once, for first occured example).
    #
    # Filter is applied only to tagged examples (`:elastics` by default).
    #
    #     RSpec.configure do |config|
    #       Elastics::RSpec.configure(config)
    #     end
    def configure(config, tag = :elastics)
      migrated = false
      error = nil
      config.around tag => true do |ex|
        if migrated
          raise error if error
          Model.list.each(&:clear_elastics)
        else
          begin
            Tasks.drop_indices
            Tasks.migrate
          rescue Error => e
            error = e
            raise e
          ensure
            migrated = true
          end
        end
        AutoRefresh.enable! { ex.run }
      end
    end
  end
end
