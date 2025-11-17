require_relative 'base'

module Goico
  module Generators
    class Launchd < Base
      def generate
        say("goico.generating_launchd")

        template_path = File.join('init', 'launchd.erb')
        output_path = File.join(@app_path, 'config', 'deploy', "#{app_name}.plist")

        template(template_path, output_path,
                 locals: launchd_locals)

        say("goico.generated_launchd", :green, path: output_path)
      end

      private

      def launchd_locals
        {
          identifier: "org.goico.#{app_name}",
          app_name: app_name,
          user: @options[:user] || ENV['USER'],
          working_directory: app_install_path,
          command: "cd #{app_install_path} && bundle exec rails server -p #{@options[:port] || 3000}",
          log_path: log_path,
          secret_key_base: @options[:secret_key_base] || 'please-change-me-in-production',
          database_url: database_url
        }
      end
    end
  end
end