# lib/goico/detectors/javascript.rb
module Goico
  module Detectors
    class Javascript < Base
      def detect
        # Check for importmap (Rails 7+ default)
        return :importmap if cached_file_exists?(File.join(@app_path, "config", "importmap.rb"))

        # Check for node/package.json
        return :node if cached_file_exists?(File.join(@app_path, "package.json"))

        # Check for specific bundlers
        return :webpack if cached_file_exists?(File.join(@app_path, "webpack.config.js"))
        return :vite if cached_file_exists?(File.join(@app_path, "vite.config.js"))
        return :esbuild if cached_file_exists?(File.join(@app_path, "esbuild.config.js"))

        # Check for node_modules as indicator
        return :node if cached_file_exists?(File.join(@app_path, "node_modules"))

        :importmap # Default for modern Rails
      end

      def system_dependencies
        case detect
        when :node, :webpack, :vite, :esbuild then %w[nodejs npm]
        else [] # importmap doesn't need Node
        end
      end
    end
  end
end