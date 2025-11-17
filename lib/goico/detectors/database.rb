module Goico
  module Detectors
    class Database
      def initialize(app_path)
        @app_path = app_path
      end

      def detect
        database_yml_path = File.join(@app_path, "config", "database.yml")

        if File.exist?(database_yml_path)
          content = File.read(database_yml_path)
          case content
          when /postgresql/ then :postgresql
          when /mysql/ then :mysql
          when /sqlite/ then :sqlite
          else :postgresql # Rails default
          end
        else
          :postgresql # Default assumption
        end
      end

      def system_dependencies
        case detect
        when :postgresql then %w[postgresql postgresql-contrib libpq-dev]
        when :mysql then %w[mysql-server libmysqlclient-dev]
        when :sqlite then %w[libsqlite3-dev]
        else []
        end
      end
    end
  end
end