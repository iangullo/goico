module Goico
  module Detectors
    class Dependencies
      def initialize(app_path)
        @app_path = app_path
      end

      def detect
        deps = base_dependencies
        deps += gem_specific_dependencies
        deps.uniq
      end

      private

      def base_dependencies
        %w[rbenv ruby-build git build-essential]
      end

      def gem_specific_dependencies
        deps = []
        gemfile_path = File.join(@app_path, "Gemfile")

        return deps unless File.exist?(gemfile_path)

        content = File.read(gemfile_path)
        deps << "redis-server" if content.include?("redis")
        deps << "libvips" if content.include?("image_processing") || content.include?("ruby-vips")
        deps << "imagemagick" if content.include?("mini_magick")

        deps
      end
    end
  end
end
