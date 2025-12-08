# lib/goico/generators/webserver.rb
require_relative 'base'

module Goico
  module Generators
    class Webserver < Base
      def generate
        webserver_type = @analysis[:infrastructure][:webserver]
        return if webserver_type == :standalone

        say("goico.generating_webserver", server: webserver_type)

        output_path = determine_output_path(webserver_type)
        template_path = File.join('webserver', determine_template_name(webserver_type))

        template(template_path, output_path, locals: webserver_locals)

        say("goico.generated_webserver", :green, path: output_path, server: webserver_type)
      end

      private

      def determine_template_name(webserver_type)
        if should_configure_ssl? && @options[:domain]
          "#{webserver_type}_ssl.conf.erb"
        else
          "#{webserver_type}.conf.erb"
        end
      end

      def determine_output_path(webserver_type)
        base_name = if should_configure_ssl? && @options[:domain]
          "#{webserver_type}_ssl.conf"
        else
          "#{webserver_type}.conf"
        end

        File.join(@app_path, 'config', 'deploy', base_name)
      end

      def webserver_locals
        config = webserver_config

        {
          app_name: app_name,
          domain: @options[:domain] || 'localhost',
          socket_path: "#{run_path}/puma.sock",
          public_path: "#{app_install_path}/public",
          log_path: log_path,
          http_port: config[:ports][:http],
          https_port: config[:ports][:https],
          ssl_enabled: config[:ssl_enabled],
          app_server_port: @analysis[:infrastructure][:app_server_port] || 3000
        }
      end
    end
  end
end