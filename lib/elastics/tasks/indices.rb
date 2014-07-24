module Elastics
  module Tasks
    module Indices
      attr_writer :indices_path

      def indices_paths
        @indices_paths ||= base_paths.map { |x| File.join x, 'indices' }
      end

      def indices_settings
        @indices_settings ||= indices_paths.map { |path| Dir["#{path}/*.yml"] }.
          flatten.sort.
          each_with_object({}) do |file, hash|
            name = File.basename file, '.yml'
            data = YAML.load_file(file)
            name = "#{config[:index_prefix]}#{name}"
            hash[name] = data[Rails.env] || data
          end
      end

      def indices
        @indices ||= config[:index] ? [config[:index]] : indices_settings.keys
      end

      def delete_indices
        indices.each do |index|
          log "Delete index #{index}"
          client.delete index: index rescue NotFound
        end
      end

      def create_indices
        indices.each do |index|
          log "Create index #{index}"
          unless client.index_exists?(index)
            client.put(index: index, data: indices_settings[index])
          end
        end
      end
    end
  end
end
