module Elastics
  module ActiveRecord
    module Instrumentation
      def request_elastics(params = {})
        data = {
          name:     name,
          request:  params,
        }
        ActiveSupport::Notifications.instrument 'request_elastics.active_record', data do
          super(params)
        end
      end
    end
  end
end
