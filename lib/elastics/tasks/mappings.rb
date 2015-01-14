module Elastics
  module Tasks
    module Mappings
      attr_writer :mappings_path

      def mappings_paths
        @mappings_paths ||= base_paths.map { |x| File.join x, 'mappings' }
      end

      # Mappings to put can be filtered with `:indices` & `:types` arrays.
      def put_mappings(options = {})
        version = options.fetch :version, :current
        filter = options[:indices].try!(:map, &:to_s)
        each_filtered(types, options[:types]) do |type|
          index = index_for_type(type)
          next if filter && !filter.include?(index)
          versioned_index = versioned_index_name(index, version)
          log "Putting mapping #{index}/#{type} (#{versioned_index}/#{type})"
          client.put_mapping index: versioned_index, type: type,
            body: mappings[type]
        end
      end

      def mappings
        @mappings ||= mappings_paths.map { |path| Dir["#{path}/*.yml"] }.
          flatten.sort.
          each_with_object({}) do |file, hash|
            name = File.basename file, '.yml'
            hash[name] = fix_mapping(name, YAML.load_file(file))
          end
      end

      # Adds missing type name in the top-level and updates properties definition.
      # It allows to write
      #
      #     properties:
      #       name: string
      #       project_id: integer
      #
      # instead of
      #
      #     task:
      #       properties:
      #         name:
      #           type: string
      #         project_id:
      #           type: integer
      def fix_mapping(name, mapping)
        mapping = {name => mapping} unless mapping.keys == [name]
        properties = mapping[name]['properties']
        properties && properties.each do |field, val|
          properties[field] = {type: val} if val.is_a?(String)
        end
        mapping
      end

      def types
        @types ||= mappings.keys
      end

      def indices
        @indices ||= (super + types.map { |type| index_for_type(type) }).uniq
      end

      def index_for_type(type)
        config[:index] || type
      end
    end
  end
end
