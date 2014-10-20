module Elastics
  module Tasks
    module Migrations
      def migrate(options = {})
        create_indices(options)
        put_mappings(options)
      end

      def migrate!(options = {})
        options_next = options.merge version: :next
        drop_indices(options_next)
        create_indices(options_next)
        put_mappings(options_next)
        reindex(options_next) if options.fetch(:reindex, true)
        forward_aliases(options)
      end

      def reindex(options = {})
        version = options.fetch(:version, :current)
        Rails.application.eager_load! if defined?(Rails)
        VersionManager.use_version version do
          models_to_reindex(options).each do |model|
            log "Reindexing #{model.elastics_index_base} into " \
              "#{model.elastics_index_name}/#{model.elastics_type_name}"
            model.reindex_elastics
          end
        end
      end

      def models_to_reindex(options = {})
        indices = options[:indices].try!(:map, &:to_s)
        types = options[:types].try!(:map, &:to_s)
        models = Elastics.models.select do |model|
          next if indices && !indices.include?(model.elastics_index_base)
          next if types && !types.include?(model.elastics_type_name)
          true
        end
        models.reject { |model| models.find { |other| model < other } }
      end
    end
  end
end
