# lib/goico/generators/base.rb
require 'thor'

module Goico
  module Generators
    class Base < Thor::Group
      include Thor::Actions

      attr_reader :app_path, :analysis, :options

      def initialize(app_path, analysis, options = {})
        @app_path = app_path
        @analysis = analysis  # Renamed from @config for clarity
        @options = options
      end

      def self.source_root
        File.expand_path('../../../../templates', __FILE__)
      end

      protected

      def say(message_key, color = :default, **options)
        message = Goico.t(message_key, **options)
        puts Rainbow(message).color(color)
      end

      def app_name
        @options[:app_name] || File.basename(@app_path)
      end

      # Platform-aware paths using detector information
      def install_prefix
        case @analysis[:platform]
        when :macos then '/usr/local'
        when :brew then '/usr/local'
        else '/usr'
        end
      end

      def app_install_path
        "#{install_prefix}/share/#{app_name}"
      end

      def config_install_path
        case @analysis[:platform]
        when :macos, :brew then "/usr/local/etc/#{app_name}"
        else "/etc/#{app_name}"
        end
      end

      def log_path
        case @analysis[:platform]
        when :macos, :brew then "/usr/local/var/log/#{app_name}"
        else "/var/log/#{app_name}"
        end
      end

      def run_path
        case @analysis[:platform]
        when :macos, :brew then "/usr/local/var/run/#{app_name}"
        else "/var/run/#{app_name}"
        end
      end

      def database_config
        db_type = @analysis[:database] || :postgresql
        {
          type: db_type,
          adapter: database_adapter(db_type),
          url: database_url(db_type)
        }
      end

      def webserver_config
        {
          type: @analysis[:infrastructure][:webserver],
          ssl_enabled: should_configure_ssl?,
          ports: @analysis[:infrastructure][:webserver_ports] || { http: 80 }
        }
      end

      def should_configure_ssl?
        @options[:ssl] || @analysis[:ssl_configuration][:should_configure]
      end

      private

      def database_adapter(db_type)
        case db_type
        when :postgresql then 'postgresql'
        when :mysql then 'mysql2'
        when :sqlite then 'sqlite3'
        else 'postgresql'
        end
      end

      def database_url(db_type)
        user = @options[:db_user] || app_name
        case db_type
        when :postgresql
          "postgresql://#{user}@localhost/#{app_name}_production"
        when :mysql
          "mysql2://#{user}@localhost/#{app_name}_production"
        else
          "sqlite3:#{app_install_path}/production.sqlite3"
        end
      end
    end
  end
end