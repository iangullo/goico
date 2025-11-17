require_relative 'base'

module Goico
  module Generators
    class Systemd < Base
      def generate
        say("goico.generating_systemd")

        template_path = File.join('init', 'systemd.erb')
        output_path = File.join(@app_path, 'config', 'deploy', "#{app_name}.service")

        template(template_path, output_path,
                 locals: systemd_locals)

        say("goico.generated_systemd", :green, path: output_path)
      end

      private

      def systemd_locals
        {
          app_name: app_name,
          description: @options[:description] || "#{app_name.humanize} Rails Application",
          user: @options[:user] || app_name,
          group: @options[:group] || app_name,
          working_directory: app_install_path,
          secret_key_base: @options[:secret_key_base] || 'please-change-me-in-production',
          database_url: database_url,
          exec_start: "/usr/bin/env bundle exec puma -C config/puma.rb",
          log_path: log_path,
          run_path: run_path
        }
      end
    end
  end
end