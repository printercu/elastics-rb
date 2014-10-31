module Elastics
  module ActiveRecord
    # To be included in `Elastics::Client`
    module Instrumentation
      def http_request(*args)
        ActiveSupport::Notifications.instrument 'request_elastics.active_record', args: args do
          super
        end
      end
    end

    module LogSubscriber
      def self.included(base)
        instance_methods.each { |method| base.method_added(method) }
      end

      def request_elastics(event)
        return unless logger.debug?

        payload = event.payload[:args]
        method, path, query, body, params = payload
        path = '/' if path.blank?
        path << "?#{query.to_param}" if query.present?
        model = params[:model]

        name = ""
        name << "#{model.name} " if model
        name << "elastics (#{event.duration.round(1)}ms)"
        request = "#{method.to_s.upcase} #{path}"
        request << " #{body}" if body.present?

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
