# lib/goico/detectors/webserver.rb
require_relative 'ssl'

module Goico
  module Detectors
    class Webserver < Base
      def detect
        # Allow override via options
        return option(:webserver).to_sym if option(:webserver)

        # Check for existing config files
        return :nginx if has_nginx_config?
        return :apache if has_apache_config?
        return :caddy if has_caddy_config?

        # Check for Passenger
        return :passenger if has_passenger?

        # Check for standalone app servers
        return :standalone if has_puma? || has_unicorn?

        # Default based on common practice
        :nginx
      end

      def ssl_configuration
        ssl_detector.detect
      end

      def should_configure_ssl?
        ssl_detector.should_configure_ssl?
      end

      def ports
        if should_configure_ssl?
          { http: 80, https: 443 }
        else
          { http: default_port }
        end
      end

      def template_name
        base_name = detect.to_s
        should_configure_ssl? ? "#{base_name}_ssl" : base_name
      end

      def system_dependencies
        case detect
        when :nginx then ['nginx']
        when :apache then ['apache2']
        when :caddy then ['caddy']
        when :passenger then passenger_dependencies
        when :standalone then standalone_dependencies
        else ['nginx'] # Default fallback
        end
      end

      # Helper method for backward compatibility or simple use cases
      def primary_port
        ports[:http]
      end

      # More descriptive name for the app server port (when behind reverse proxy)
      def app_server_port
        case detect
        when :standalone then default_port
        else 3000 # Default app server port behind reverse proxy
        end
      end

      private

      def ssl_detector
        @ssl_detector ||= Ssl.new(@app_path, @options)
      end

      def has_nginx_config?
        Dir[File.join(@app_path, 'config', 'nginx*')].any?
      rescue => e
        log_warning("Failed to check nginx config: #{e.message}")
        false
      end

      def has_apache_config?
        Dir[File.join(@app_path, 'config', 'apache*')].any? ||
        Dir[File.join(@app_path, 'config', 'httpd*')].any?
      rescue => e
        log_warning("Failed to check apache config: #{e.message}")
        false
      end

      def has_caddy_config?
        cached_file_exists?(File.join(@app_path, 'Caddyfile'))
      end

      def has_passenger?
        has_gemfile? && cached_gemfile_content.include?('passenger')
      end

      def has_puma?
        cached_file_exists?(File.join(@app_path, 'config/puma.rb'))
      end

      def has_unicorn?
        cached_file_exists?(File.join(@app_path, 'config/unicorn.rb'))
      end

      def passenger_dependencies
        if cached_file_exists?(File.join(@app_path, 'config', 'nginx.conf'))
          ['nginx', 'passenger']
        else
          ['apache2', 'passenger'] # Default to Apache
        end
      end

      def standalone_dependencies
        # Even standalone might need some packages
        deps = []
        deps << 'curl' # Often useful for health checks
        deps
      end

      def detect_from_config
        # Try to detect port from puma config
        if has_puma?
          puma_config = cached_file_content(File.join(@app_path, 'config/puma.rb'))
          if puma_config.match(/port\s+(\d+)/)
            return Regexp.last_match(1).to_i
          end
        end

        # Try to detect from other config files
        nil # Return nil if no specific port detected
      end

      def default_port
        detected_port = detect_from_config
        detected_port || 3000 # Fallback to Rails default
      end
    end
  end
end