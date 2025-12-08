# lib/goico/generators/app_config.rb
require_relative 'base'

module Goico
  module Generators
    class RailsConfig < Base
      def generate
        say("goico.generating_app_config")

        generate_puma_config
        generate_database_config
        generate_env_file

        say("goico.generated_app_config", :green)
      end

      private

      def generate_puma_config
        return if @analysis[:infrastructure][:app_server] != :puma

        template_path = File.join('common', 'puma', 'config.erb')
        output_path = File.join(@app_path, 'config', 'puma.rb')

        unless File.exist?(output_path)
          template(template_path, output_path, locals: puma_locals)
        end
      end

      def generate_database_config
        template_path = File.join('database', 'setup.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'database.yml')

        template(template_path, output_path, locals: database_locals)
      end

      def generate_env_file
        template_path = File.join('scripts', 'environment.erb')
        output_path = File.join(@app_path, 'config', 'deploy', '.env.production')

        template(template_path, output_path, locals: environment_locals)
      end

      def puma_locals
        {
          app_name: app_name,
          workers: @options[:puma_workers] || 2,
          threads: @options[:puma_threads] || [0, 16],
          bind: @analysis[:infrastructure][:webserver] == :standalone ? 'tcp://0.0.0.0:3000' : "unix://#{run_path}/puma.sock",
          pidfile: "#{run_path}/puma.pid",
          log_path: log_path
        }
      end

      def database_locals
        config = database_config
        {
          adapter: config[:adapter],
          database: "#{app_name}_production",
          username: @options[:db_user] || app_name,
          password: @options[:db_password] || 'please-change-me',
          host: 'localhost',
          pool: 5,
          timeout: 5000
        }
      end

      def environment_locals
        {
          secret_key_base: @options[:secret_key_base] || 'please-change-me-in-production',
          database_url: database_config[:url],
          rails_env: 'production',
          rails_serve_static_files: 'true',
          rails_log_level: 'info'
        }
      end
    end
  end
end