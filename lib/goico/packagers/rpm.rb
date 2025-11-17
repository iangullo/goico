require_relative 'base'

module Goico
  module Packagers
    class Rpm < Base
      def build_package
        say("goico.building_rpm_package")

        fpm_command = [
          "fpm -s dir -t rpm",
          "-n #{package_name}",
          "-v #{package_version}",
          "--iteration #{package_iteration}",
          "--rpm-user #{service_user}",
          "--rpm-group #{service_group}",
          "--category web",
          *package_dependencies,
          "-C #{@build_dir}",
          "."
        ].join(' ')

        system(fpm_command) || raise(Error, "Failed to build RPM package")
      end

      private

      def package_name
        @options[:package_name] || "#{app_name}-server"
      end

      def package_dependencies
        deps = []

        # Database
        deps << "--depends postgresql" if @config[:database] == :postgresql
        deps << "--depends mariadb-server" if @config[:database] == :mysql

        # Webserver - different package names on RPM systems
        case @config[:infrastructure][:webserver]
        when :nginx then deps << "--depends nginx"
        when :apache then deps << "--depends httpd"
        end

        # Infrastructure
        infra_deps = Detectors::Infrastructure.new(@app_path).system_dependencies
        # Map debian names to rpm names
        infra_deps.each do |dep|
          rpm_name = case dep
                     when 'redis-server' then 'redis'
                     when 'apache2' then 'httpd'
                     when 'rbenv' then 'rbenv'
                     else dep
                     end
          deps << "--depends #{rpm_name}"
        end

        deps
      end
    end
  end
end