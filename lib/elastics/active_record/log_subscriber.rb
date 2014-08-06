module Elastics
  module ActiveRecord
    module LogSubscriber
      def self.included(base)
        instance_methods.each { |method| base.method_added(method) }
      end

      def request_elastics(event)
        return unless logger.debug?

        payload = event.payload

        name    = "#{payload[:name]} elastics (#{event.duration.round(1)}ms)"
        request = payload[:request].to_json

        if odd?
          name    = color(name, ActiveSupport::LogSubscriber::CYAN, true)
          request = color(request, nil, true)
        else
          name = color(name, ActiveSupport::LogSubscriber::MAGENTA, true)
        end

        debug "  #{name}  #{request}"
      end
    end
  end
end
