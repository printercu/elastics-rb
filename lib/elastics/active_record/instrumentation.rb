module Elastics
  module ActiveRecord
    # To be included in `Elastics::Client`
    module Instrumentation
      class << self
        def install
          if Client.respond_to?(:prepend)
            Client.prepend self
          else
            Client.send :include, Fallback
          end
          unless ::ActiveRecord::LogSubscriber < LogSubscriber
            ::ActiveRecord::LogSubscriber.send :include, LogSubscriber
          end
        end
      end

      def http_request(*args)
        ActiveSupport::Notifications.instrument 'request_elastics.active_record', args: args do
          super
        end
      end

      # old rubies support
      module Fallback
        extend ActiveSupport::Concern

        included do
          alias_method_chain :http_request, :instrumentation
        end

        def http_request_with_instrumentation(*args)
          ActiveSupport::Notifications.instrument 'request_elastics.active_record', args: args do
            http_request_without_instrumentation(*args)
          end
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
