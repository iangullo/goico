require_relative 'base'

module Goico
  module Generators
    class Initd < Base
      def generate
        say("goico.generating_initd")

        template_path = File.join('init', 'initd.erb')
        output_path = File.join(@app_path, 'config', 'deploy', app_name)

        template(template_path, output_path,
                 locals: initd_locals)

        FileUtils.chmod(0755, output_path)
        say("goico.generated_initd", :green, path: output_path)
      end

      private

      def initd_locals
        {
          app_name: app_name,
          description: @options[:description] || "#{app_name.humanize} Rails Application",
          user: @options[:user] || app_name,
          group: @options[:group] || app_name,
          working_directory: app_install_path,
          daemon: "/usr/bin/env",
          daemon_args: "bundle exec rails server -e production",
          pidfile: "#{run_path}/#{app_name}.pid"
        }
      end
    end
  end
end