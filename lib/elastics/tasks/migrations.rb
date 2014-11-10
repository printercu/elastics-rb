module Elastics
  module Tasks
    module Migrations
      def migrate(options = {})
        create_indices(options)
        put_mappings(options)
      end

      def migrate!(options = {})
        options_next = options.merge version: :next
        need_reindex = options.fetch(:reindex, true)
        drop_indices(options_next)
        create_indices(options_next)
        put_mappings(options_next)
        started_at = reindex(options_next) if need_reindex
        forward_aliases(options)
        if need_reindex
          reindex(options.merge(version: :current, updated_after: started_at))
        end
      end

      # Runs `#reindex_elastics` on matching models.
      # Returns hash with timestamps with reindex start time for each model.
      # Supports this kind of hash as `:updated_after` option, to reindex
      # only updated records.
      def reindex(options = {})
        version = options.fetch(:version, :current)
        updated_after = options.fetch(:updated_after, {})
        Rails.application.eager_load! if defined?(Rails)
        VersionManager.use_version version do
          Hash[models_to_reindex(options).map do |model|
            started_at = Time.now
            log "Reindexing #{model.elastics_index_base} into " \
              "#{model.elastics_index_name}/#{model.elastics_type_name}"
            model.reindex_elastics(updated_after: updated_after[model])
            [model, started_at]
          end]
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
