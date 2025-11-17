require_relative 'base'

module Goico
  module Generators
    class Ssl < Base
      def generate
        return unless @options[:ssl]

        say("goico.generating_ssl")

        # Generate SSL setup script
        generate_ssl_script

        # Generate SSL-enabled webserver config
        generate_ssl_webserver_config

        say("goico.generated_ssl", :green)
      end

      private

      def generate_ssl_script
        template_path = File.join('scripts', 'ssl_setup.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'ssl_setup.sh')

        template(template_path, output_path,
                 locals: ssl_script_locals)

        FileUtils.chmod(0755, output_path)
      end

      def generate_ssl_webserver_config
        webserver_type = @config[:infrastructure][:webserver]
        return unless %w[nginx apache].include?(webserver_type.to_s)

        template_path = File.join('webserver', "#{webserver_type}_ssl.conf.erb")
        output_path = File.join(@app_path, 'config', 'deploy', "#{webserver_type}_ssl.conf")

        template(template_path, output_path,
                 locals: ssl_webserver_locals)
      end

      def ssl_script_locals
        {
          app_name: app_name,
          domain: @options[:domain],
          email: @options[:email] || "admin@#{@options[:domain]}",
          webserver: @config[:infrastructure][:webserver],
          package_manager: detect_package_manager,
          config_path: config_install_path
        }
      end

      def ssl_webserver_locals
        {
          app_name: app_name,
          domain: @options[:domain],
          socket_path: "#{run_path}/puma.sock",
          public_path: "#{app_install_path}/public",
          log_path: log_path
        }
      end

      def detect_package_manager
        # Detect package manager based on system
        if File.exist?('/etc/debian_version')
          'apt'
        elsif File.exist?('/etc/redhat-release')
          'yum'
        elsif File.exist?('/etc/arch-release')
          'pacman'
        else
          'unknown'
        end
      end
    end
  end
end