# lib/goico/generators/ssl.rb
require_relative 'base'

module Goico
  module Generators
    class Ssl < Base
      def generate
        return unless should_configure_ssl?
        return unless @options[:domain] # Need domain for SSL

        say("goico.generating_ssl")

        generate_ssl_script
        generate_certbot_config if using_letsencrypt?

        say("goico.generated_ssl", :green)
      end

      private

      def generate_ssl_script
        template_path = File.join('scripts', 'ssl_setup.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'ssl_setup.sh')

        template(template_path, output_path, locals: ssl_script_locals)
        FileUtils.chmod(0755, output_path)
      end

      def generate_certbot_config
        template_path = File.join('scripts', 'certbot_renewal.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'certbot_renewal.conf')

        template(template_path, output_path, locals: certbot_locals)
      end

      def using_letsencrypt?
        !@analysis[:ssl_configuration][:existing_certificates]
      end

      def ssl_script_locals
        {
          app_name: app_name,
          domain: @options[:domain],
          email: @options[:email] || "admin@#{@options[:domain]}",
          webserver: @analysis[:infrastructure][:webserver],
          package_manager: @analysis[:platform_package_manager],
          config_path: config_install_path,
          use_letsencrypt: using_letsencrypt?,
          existing_certs: @analysis[:ssl_configuration][:existing_certificates]
        }
      end

      def certbot_locals
        {
          domain: @options[:domain],
          email: @options[:email] || "admin@#{@options[:domain]}",
          webroot_path: "#{app_install_path}/public"
        }
      end
    end
  end
end