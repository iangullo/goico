# lib/goico/detectors/base.rb
module Goico
  module Detectors
    class Base
      def initialize(app_path, options = {})
        @app_path = app_path
        @options = options
        @cache = {}
      end

      protected

      # Caching methods
      def cached_file_content(path)
        @cache[path] ||= read_file_safely(path)
      end

      def cached_gemfile_content
        @cache[:gemfile] ||= read_file_safely(gemfile_path)
      end

      def cached_file_exists?(path)
        @cache[:"exists_#{path}"] ||= File.exist?(path)
      end

      # File operations with error handling
      def read_file_safely(path)
        return "" unless File.exist?(path)
        File.read(path)
      rescue => e
        log_warning("Failed to read #{path}: #{e.message}")
        ""
      end

      def file_exists_safely?(path)
        File.exist?(path)
      rescue => e
        log_warning("Failed to check #{path}: #{e.message}")
        false
      end

      # Option access with defaults
      def option(key, default = nil)
        @options&.fetch(key, default) || default
      end

      # Logging
      def log_warning(message)
        puts "WARNING: #{message}" if option(:verbose, false)
      end

      # Common paths
      def gemfile_path
        File.join(@app_path, "Gemfile")
      end

      def has_gemfile?
        file_exists_safely?(gemfile_path)
      end
    end
  end
end