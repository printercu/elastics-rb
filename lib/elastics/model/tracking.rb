module Elastics
  module Model
    class << self
      attr_reader :list

      def reset_list
        @list = []
      end

      def track(model)
        if !model.respond_to?(:track_elastics_model?) || model.track_elastics_model?
          list << model
        end
      end
    end

    reset_list

    module Tracking
      def self.extended(base)
        Model.track(base)
      end

      def inherited(base)
        super.tap { Model.track(base) }
      end
    end
  end
end
