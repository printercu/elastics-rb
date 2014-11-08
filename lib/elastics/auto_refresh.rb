module Elastics
  module AutoRefresh
    METHODS = %w(put post patch delete)
    SKIP_IDS = %w(_refresh _search)

    class << self
      def enabled?
        Thread.current[:elastics_test_mode]
      end

      def enabled=(value)
        value = !!value
        Client.send(:include, self) if value && !Client.include?(self)
        Thread.current[:elastics_test_mode] = value
      end

      def use(value)
        old_value = enabled?
        self.enabled = value
        block_given? ? yield : value
      ensure
        self.enabled = old_value if block_given?
      end

      def enable!(&block)
        use(true, &block)
      end

      def disable!(&block)
        use(false, &block)
      end

      def included(base)
        base.send :alias_method, :request_without_test_mode, :request
        base.send :alias_method, :request, :request_with_test_mode
      end
    end

    def request_with_test_mode(params)
      request_without_test_mode(params).tap do
        next unless AutoRefresh.enabled?
        next if SKIP_IDS.include?(params[:id].to_s.downcase)
        next unless METHODS.include?(params[:method].to_s.downcase)
        refresh(params[:index])
      end
    end
  end
end
