module Elastics
  module Instrumentation
    autoload :ActiveSupport, 'elastics/instrumentation/active_support'

    class << self
      attr_writer :body_prettifier

      def prettify_body(str)
        case @body_prettifier
        when :ap  then prettify_json(str, &:awesome_inspect)
        when :pp  then prettify_json(str, &:pretty_inspect)
        when true then prettify_json(str, &JSON.method(:pretty_generate))
        when Proc then @body_prettifier.call(str)
        else str
        end
      end

      def prettify_json(str, &block)
        data = [JSON.parse(str)] rescue nil
        data ||= str.split("\n").map { |x| JSON.parse(x) } rescue nil
        if data
          data.map(&block).join("\n")
        else
          str
        end
      end
    end
  end
end
