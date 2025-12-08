# lib/goico/detectors/dependencies.rb
module Goico
  module Detectors
    class Dependencies < Base
      def detect
        {
          system: system_dependencies,
          ruby: ruby_dependencies,
          database: database_dependencies
        }
      end

      def system_dependencies
        deps = base_dependencies
        deps += gem_specific_dependencies
        deps += javascript_dependencies
        deps.uniq
      end

      private

      def base_dependencies
        # These are common build dependencies
        %w[git curl wget build-essential]
      end

      def gem_specific_dependencies
        deps = []
        return deps unless has_gemfile?

        content = cached_gemfile_content

        # Image processing
        deps << "libvips" if content.include?("image_processing") || content.include?("ruby-vips")
        deps << "imagemagick" if content.include?("mini_magick")

        # XML/JSON parsing
        deps << "libxml2-dev" if content.include?("nokogiri")
        deps << "libxslt-dev" if content.include?("nokogiri")

        # Cryptography
        deps += %w[libssl-dev libffi-dev] if content.include?("bcrypt") || content.include?("rbnacl")

        # Database clients (development headers)
        deps << "libpq-dev" if content.include?("pg")
        deps << "default-libmysqlclient-dev" if content.include?("mysql2")
        deps << "libsqlite3-dev" if content.include?("sqlite3")

        deps
      end

      def javascript_dependencies
        Javascript.new(@app_path, @options).system_dependencies
      end

      def database_dependencies
        Database.new(@app_path, @options).system_dependencies
      end

      def ruby_dependencies
        [] # system dependencies handle Ruby installation
      end
    end
  end
end