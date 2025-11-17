require 'thor'

module Goico
  module Generators
    class Base < Thor::Group
      include Thor::Actions

      attr_reader :app_path, :config, :options

      def initialize(app_path, config, options = {})
        @app_path = app_path
        @config = config
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
        @config[:app_name]
      end

      def install_prefix
        case @options[:type]
        when 'brew' then '/usr/local'
        else '/usr'
        end
      end

      def app_install_path
        "#{install_prefix}/share/#{app_name}"
      end

      def config_install_path
        case @options[:type]
        when 'brew' then "/usr/local/etc/#{app_name}"
        else "/etc/#{app_name}"
        end
      end

      def log_path
        case @options[:type]
        when 'brew' then "/usr/local/var/log/#{app_name}"
        else "/var/log/#{app_name}"
        end
      end

      def run_path
        case @options[:type]
        when 'brew' then "/usr/local/var/run/#{app_name}"
        else "/var/run/#{app_name}"
        end
      end

      def database_url
        case @config[:database]
        when :postgresql
          "postgresql://#{@options[:db_user] || app_name}@localhost/#{app_name}_production"
        when :mysql
          "mysql2://#{@options[:db_user] || app_name}@localhost/#{app_name}_production"
        else
          "sqlite3:#{app_install_path}/production.sqlite3"
        end
      end
    end
  end
end