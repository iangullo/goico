# lib/goico/detectors/database.rb
module Goico
  module Detectors
    class Database < Base
      def detect
        database_yml_path = File.join(@app_path, "config", "database.yml")
        content = cached_file_content(database_yml_path)

        if content && !content.empty?
          case content
          when /postgresql|postgres|pg/ then :postgresql
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

      def adapter_name
        case detect
        when :postgresql then 'postgresql'
        when :mysql then 'mysql2'
        when :sqlite then 'sqlite3'
        else 'postgresql'
        end
      end
    end
  end
end