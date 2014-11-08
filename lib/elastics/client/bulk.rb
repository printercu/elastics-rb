module Elastics
  class Client
    module Bulk
      def bulk(params = {})
        builder = Builder.new
        yield builder
        if builder.any?
          request({body: builder.body, method: :post, id: :_bulk}.merge! params)
        end
      end

      class Builder
        attr_reader :actions

        def initialize
          @actions = []
        end

        def any?
          @actions.any?
        end

        def body
          @actions.map(&:to_json).join("\n".freeze) + "\n"
        end

        def add_action(action, params, data = nil)
          params = {_id: params} unless params.is_a?(Hash)
          @actions << {action => params}
          @actions << data if data
        end

        [:index, :create, :update].each do |action|
          define_method(action) do |params, data|
            add_action(action, params, data)
          end
        end

        def update_doc(params, fields)
          update(params, doc: fields)
        end

        def delete(params)
          add_action(:delete, params)
        end
      end
    end
  end
end
