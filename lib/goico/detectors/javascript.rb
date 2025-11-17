module Goico
  module Detectors
    class Javascript
      def initialize(app_path)
        @app_path = app_path
      end

      def detect
        # Check for importmap (Rails 7+ default)
        return :importmap if File.exist?(File.join(@app_path, "config", "importmap.rb"))

        # Check for node/package.json
        return :node if File.exist?(File.join(@app_path, "package.json"))

        # Check for webpack
        return :webpack if File.exist?(File.join(@app_path, "webpack.config.js"))

        :importmap # Default for modern Rails
      end

      def system_dependencies
        case detect
        when :node, :webpack then %w[nodejs npm]
        else [] # importmap doesn't need Node
        end
      end
    end
  end
end