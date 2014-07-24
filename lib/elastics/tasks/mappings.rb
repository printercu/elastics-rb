module Elastics
  module Tasks
    module Mappings
      attr_writer :mappings_path

      def mappings_paths
        @mappings_paths ||= base_paths.map { |x| File.join x, 'mappings' }
      end

      def put_mappings
        mappings.each do |type, mapping|
          index = index_for_type(type)
          log "Put mapping #{index}/#{type}"
          client.put_mapping index: index, type: type, data: mapping
        end
      end

      def mappings
        @mappings ||= mappings_paths.map { |path| Dir["#{path}/*.yml"] }.
          flatten.sort.
          each_with_object({}) do |file, hash|
            name = File.basename file, '.yml'
            hash[name] = YAML.load_file(file)
          end
      end

      def types
        @types ||= mappings.keys
      end

      def indices
        @indices ||= (super + types.map { |type| index_for_type(type) }).uniq
      end

      def index_for_type(type)
        config[:index] || "#{config[:index_prefix]}#{type}"
      end
    end
  end
end
