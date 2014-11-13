require 'active_support/core_ext/object/blank'
require 'active_support/log_subscriber'
require 'active_support/notifications'

module Elastics
  module Instrumentation
    module ActiveSupport
      class << self
        def install
          if Client.respond_to?(:prepend)
            Client.prepend self
          else
            Client.send :include, Ruby19Fallback
          end
          LogSubscriber.attach_to :elastics
        end
      end

      def http_request(*args)
        ::ActiveSupport::Notifications.instrument 'http_request.elastics', args: args do
          super
        end
      end

      # old rubies support
      module Ruby19Fallback
        def self.included(base)
          base.alias_method_chain :http_request, :as_instrumentation
        end

        def http_request_with_as_instrumentation(*args)
          ::ActiveSupport::Notifications.instrument 'http_request.elastics', args: args do
            http_request_without_as_instrumentation(*args)
          end
        end
      end

      class LogSubscriber < ::ActiveSupport::LogSubscriber
        def http_request(event)
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
          request << " #{Instrumentation.prettify_body(body)}" if body.present?

          if odd?
            name    = color(name, ::ActiveSupport::LogSubscriber::CYAN, true)
            request = color(request, nil, true)
          else
            name = color(name, ::ActiveSupport::LogSubscriber::MAGENTA, true)
          end

          debug "  #{name}  #{request}"
        end

        def odd?
          @odd = !@odd
        end
      end
    end
  end
end
