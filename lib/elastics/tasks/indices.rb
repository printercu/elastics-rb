module Elastics
  module Tasks
    # Most of methods accepts `options` hash with:
    # - `:indices` - array of indices to perform action on
    # - `:version` - mapping version to use in method
    #
    module Indices
      attr_writer :indices_path

      def indices_paths
        @indices_paths ||= base_paths.map { |x| File.join x, 'indices' }
      end

      # Merges settings from single files and dirs.
      def indices_settings
        @indices_settings ||= indices_from_files.merge!(indices_from_dirs)
      end

      # Reads indices settings from single yml file.
      # Setting can be given specific for env or one for all envs.
      #
      #     tweet:
      #       development:
      #         settings:
      #           number_of_shards: 5
      #       production:
      #         settings:
      #           number_of_shards: 10
      #
      #     user:
      #       settings:
      #         number_of_shards: 5
      def indices_from_files
        indices_paths.each_with_object({}) do |path, hash|
          file = "#{path}.yml"
          next unless File.exists?(file)
          load_yaml(file).each do |name, data|
            hash[name] = data[Rails.env] || data
          end
        end
      end

      # Reads indices settings from separate files. Index name is taken from
      # file name, setting can be given specific for env or one for all envs.
      #
      #     development:
      #       settings:
      #         number_of_shards: 5
      #     production:
      #       settings:
      #         number_of_shards: 10
      #
      #     # or
      #     settings:
      #       number_of_shards: 1
      def indices_from_dirs
        indices_paths.map { |path| Dir["#{path}/*.yml"] }.
          flatten.sort.
          each_with_object({}) do |file, hash|
            name = File.basename file, '.yml'
            data = load_yaml(file)
            hash[name] = data[Rails.env] || data
          end
      end

      def indices
        @indices ||= config[:index] ? [config[:index]] : indices_settings.keys
      end

      def versioned_index_name(*args)
        version_manager.index_name *args
      end

      def purge(keep_data = false)
        unless keep_data
          drop_indices
          drop_indices version: :next
        end
        index = version_manager.service_index
        log "Deleting index #{index}"
        version_manager.reset
        client.delete index: index
      end

      def drop_indices(options = {})
        version = options.fetch :version, :current
        each_filtered(indices, options[:indices]) do |index|
          versioned_index = versioned_index_name(index, version)
          log "Deleting index #{index} (#{versioned_index})"
          client.delete index: versioned_index
        end
      end

      def create_indices(options = {})
        version = options.fetch :version, :current
        each_filtered(indices, options[:indices]) do |index|
          versioned_index = versioned_index_name(index, version)
          exists = client.index_exists?(versioned_index)
          log_msg = "Creating index #{index} (#{versioned_index})"
          log_msg << ' - Skipping: exists' if exists
          log log_msg
          unless exists
            client.put(index: versioned_index, body: indices_settings[index])
          end
        end
        manage_aliases :add, options if version.to_s == 'current'
      end

      # Action can be :add or :remove.
      def manage_aliases(action, options = {})
        version = options.fetch :version, :current
        post_aliases(options) do |index|
          alias_action(action, index, version)
        end
      end

      def forward_aliases(options = {})
        new_versions = {}
        post_aliases options do |index|
          new_versions[index] = version_manager.next_version index
          if client.index_exists?(versioned_index_name(index, :current))
            [
              alias_action(:remove, index, :current),
              alias_action(:add, index, :next),
            ]
          else
            alias_action(:add, index, :next)
          end
        end
        drop_indices(options.merge version: :current) if options.fetch(:drop, true)
        new_versions.each do |index, version|
          version_manager.set index, current: version
        end
      end

      def alias_action(action, index, version)
        {action => {
          index: versioned_index_name(index, version),
          alias: versioned_index_name(index, :alias),
        }}
      end

      def post_aliases(options = {}, &block)
        actions = each_filtered(indices, options[:indices]).map(&block).flatten
        log "Posting aliases: #{actions.inspect}"
        client.post id: :_aliases, body: {actions: actions} if actions.any?
      end
    end
  end
end
