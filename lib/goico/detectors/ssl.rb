# lib/goico/detectors/ssl.rb
module Goico
  module Detectors
    class Ssl < Base
      def detect
        {
          forced_ssl: detect_forced_ssl,
          hsts: detect_hsts,
          secure_cookies: detect_secure_cookies,
          existing_certificates: detect_existing_certs,
          configuration_hints: detect_config_hints
        }
      end

      def should_configure_ssl?
        detection = detect
        detection[:forced_ssl] ||
        detection[:hsts] ||
        detection[:secure_cookies] ||
        detection[:existing_certificates] ||
        detection[:configuration_hints]
      end

      private

      def detect_forced_ssl
        # Check config/application.rb or environment configs
        config_files = [
          'config/application.rb',
          'config/environments/production.rb',
          'config/environments/staging.rb'
        ]

        config_files.any? do |file|
          path = File.join(@app_path, file)
          if cached_file_exists?(path)
            content = cached_file_content(path)
            content.include?('config.force_ssl') &&
            content.match(/config\.force_ssl\s*=\s*true/)
          end
        end
      end

      def detect_hsts
        # Check for HSTS headers in initializers or middleware
        initializers_path = File.join(@app_path, 'config/initializers')
        return false unless File.directory?(initializers_path)

        Dir[File.join(initializers_path, '**/*.rb')].any? do |file|
          content = cached_file_content(file)
          content.include?('Strict-Transport-Security') ||
          content.include?('hsts') ||
          content.include?('force_ssl')
        end
      end

      def detect_secure_cookies
        # Check for secure cookie configuration
        config_files = [
          'config/application.rb',
          'config/environments/production.rb',
          'config/initializers/session_store.rb'
        ]

        config_files.any? do |file|
          path = File.join(@app_path, file)
          if cached_file_exists?(path)
            content = cached_file_content(path)
            content.include?('secure: true') ||
            content.include?('config.force_ssl = true') ||
            content.match(/secure.*=>.*true/)
          end
        end
      end

      def detect_existing_certs
        # Check for existing SSL certificates in the project
        cert_patterns = [
          'config/ssl/*.crt',
          'config/ssl/*.key',
          'config/*.pem',
          'ssl/*.crt',
          'ssl/*.key',
          'certificates/*'
        ]

        cert_patterns.any? do |pattern|
          !Dir[File.join(@app_path, pattern)].empty?
        end
      end

      def detect_config_hints
        # Look for environment variables or comments suggesting SSL
        env_files = [
          '.env',
          '.env.production',
          '.env.example',
          'config/deploy.rb',
          'config/deploy/*.rb'
        ]

        ssl_keywords = ['SSL', 'CERT', 'HTTPS', 'TLS', '443', 'certbot', 'letsencrypt']

        env_files.any? do |file|
          path = File.join(@app_path, file)
          if cached_file_exists?(path)
            content = cached_file_content(path)
            ssl_keywords.any? { |keyword| content.include?(keyword) }
          end
        end
      end
    end
  end
end