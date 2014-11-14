module Elastics
  module Instrumentation
    autoload :ActiveSupport, 'elastics/instrumentation/active_support'

    PRETTIFIERS = {
      ap:     ->(str) { prettify_json(str, &:awesome_inspect) },
      pp:     ->(str) { prettify_json(str, &:pretty_inspect) },
      true => ->(str) { prettify_json(str, &JSON.method(:pretty_generate)) },
    }

    class << self
      def body_prettifier=(value)
        @body_prettifier = case value
        when Proc, nil, false then value
        else PRETTIFIERS[value] or raise 'Invalid prettifier'
        end
      end

      def prettify_body(str)
        if @body_prettifier
          @body_prettifier.call(str)
        else
          str
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
