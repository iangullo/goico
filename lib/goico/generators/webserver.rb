require_relative 'base'

module Goico
  module Generators
    class Webserver < Base
      def generate
        webserver_type = @config[:infrastructure][:webserver]
        say("goico.generating_webserver", server: webserver_type)

        # Choose template based on SSL
        template_name = if @options[:ssl] && @options[:domain]
          "#{webserver_type}_ssl.conf.erb"
        else
          "#{webserver_type}.conf.erb"
        end

        template_path = File.join('webserver', template_name)
        output_path = determine_output_path(webserver_type)

        template(template_path, output_path,
                 locals: webserver_locals)

        say("goico.generated_webserver", :green, path: output_path, server: webserver_type)
      end

      private

      def determine_output_path(webserver_type)
        base_name = if @options[:ssl] && @options[:domain]
          "#{webserver_type}_ssl.conf"
        else
          "#{webserver_type}.conf"
        end

        File.join(@app_path, 'config', 'deploy', base_name)
      end

      def webserver_locals
        {
          app_name: app_name,
          domain: @options[:domain] || 'localhost',
          socket_path: "#{run_path}/puma.sock",
          public_path: "#{app_install_path}/public",
          log_path: log_path
        }
      end
    end
  end
end