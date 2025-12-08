# lib/goico/generators/service.rb
require_relative 'base'

module Goico
  module Generators
    class Service < Base
      def generate
        service_type = determine_service_type
        say("goico.generating_service", service: service_type)

        case service_type
        when :systemd then generate_systemd
        when :launchd then generate_launchd
        when :initd then generate_initd
        end
      end

      private

      def determine_service_type
        # Use detector data or options
        @options[:service_type] ||
        @analysis[:platform_service_type] ||
        detect_service_type
      end

      def detect_service_type
        case @analysis[:platform]
        when :macos then :launchd
        when :linux
          # Detect init system
          if File.exist?('/run/systemd/system')
            :systemd
          else
            :initd
          end
        else :systemd # Default
        end
      end

      def generate_systemd
        template_path = File.join('init', 'systemd.erb')
        output_path = File.join(@app_path, 'config', 'deploy', "#{app_name}.service")

        template(template_path, output_path, locals: systemd_locals)
        say("goico.generated_systemd", :green, path: output_path)
      end

      def generate_launchd
        template_path = File.join('init', 'launchd.erb')
        output_path = File.join(@app_path, 'config', 'deploy', "#{app_name}.plist")

        template(template_path, output_path, locals: launchd_locals)
        say("goico.generated_launchd", :green, path: output_path)
      end

      def generate_initd
        template_path = File.join('init', 'initd.erb')
        output_path = File.join(@app_path, 'config', 'deploy', app_name)

        template(template_path, output_path, locals: initd_locals)
        FileUtils.chmod(0755, output_path)
        say("goico.generated_initd", :green, path: output_path)
      end

      def systemd_locals
        {
          app_name: app_name,
          description: @options[:description] || "#{app_name.humanize} Rails Application",
          user: @options[:user] || app_name,
          group: @options[:group] || app_name,
          working_directory: app_install_path,
          environment: service_environment,
          exec_start: determine_exec_start,
          log_path: log_path,
          run_path: run_path
        }
      end

      def launchd_locals
        {
          identifier: "org.goico.#{app_name}",
          app_name: app_name,
          user: @options[:user] || ENV['USER'],
          working_directory: app_install_path,
          environment: service_environment,
          command: determine_exec_start,
          log_path: log_path
        }
      end

      def initd_locals
        {
          app_name: app_name,
          description: @options[:description] || "#{app_name.humanize} Rails Application",
          user: @options[:user] || app_name,
          group: @options[:group] || app_name,
          working_directory: app_install_path,
          environment: service_environment_vars,
          daemon: determine_daemon_command,
          pidfile: "#{run_path}/#{app_name}.pid"
        }
      end

      def service_environment
        env = {
          'RAILS_ENV' => 'production',
          'RAILS_LOG_TO_STDOUT' => 'true',
          'DATABASE_URL' => database_config[:url],
          'SECRET_KEY_BASE' => @options[:secret_key_base] || 'please-change-me-in-production'
        }

        # Add any custom environment variables from options
        @options[:environment]&.each { |k, v| env[k.to_s] = v }
        env
      end

      def service_environment_vars
        service_environment.map { |k, v| "#{k}=#{v}" }.join(' ')
      end

      def determine_exec_start
        app_server = @analysis[:infrastructure][:app_server] || :puma
        case app_server
        when :puma
          "bundle exec puma -C config/puma.rb"
        when :unicorn
          "bundle exec unicorn -c config/unicorn.rb"
        else
          "bundle exec rails server -e production"
        end
      end

      def determine_daemon_command
        "/usr/bin/env #{service_environment_vars} #{determine_exec_start}"
      end
    end
  end
end