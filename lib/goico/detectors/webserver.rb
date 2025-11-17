module Goico
  module Detectors
    class Webserver
      def initialize(app_path)
        @app_path = app_path
      end

      def detect
        # Check for explicit configuration
        return @options[:webserver].to_sym if @options && @options[:webserver]

        # Check for existing config files
        return :nginx if File.exist?(File.join(@app_path, 'config', 'nginx.conf'))
        return :apache if File.exist?(File.join(@app_path, 'config', 'apache.conf'))

        # Check for Puma as an indicator of standalone
        return :standalone if File.exist?(File.join(@app_path, 'config', 'puma.rb'))

        # Default based on common practice
        :nginx
      end

      def system_dependencies
        case detect
        when :nginx then ['nginx']
        when :apache then ['apache2'] # or 'httpd' on some systems
        when :standalone then [] # No additional webserver needed
        else ['nginx'] # Default fallback
        end
      end

      def port
        case detect
        when :standalone then 3000
        else 80 # Reverse proxy setups
        end
      end

      def template_name
        detect.to_s
      end
    end
  end
end