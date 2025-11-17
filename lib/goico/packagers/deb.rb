require_relative 'base'

module Goico
  module Packagers
    class Deb < Base
      def build_package
        say("goico.building_deb_package")

        fpm_command = [
          "fpm -s dir -t deb",
          "-n #{package_name}",
          "-v #{package_version}",
          "--iteration #{package_iteration}",
          "--deb-user #{service_user}",
          "--deb-group #{service_group}",
          "--category web",
          "--url 'https://#{app_name}.com'",
          "--description '#{package_description}'",
          *package_dependencies,
          "-C #{@build_dir}",
          "."
        ].join(' ')

        system(fpm_command) || raise(Error, "Failed to build DEB package")
      end

      private

      def package_name
        @options[:package_name] || "#{app_name}-server"
      end

      def package_version
        @options[:version] || '1.0.0'
      end

      def package_iteration
        @options[:iteration] || '1'
      end

      def service_user
        @options[:user] || app_name
      end

      def service_group
        @options[:group] || app_name
      end

      def package_description
        @options[:description] || "#{app_name.humanize} Rails Application"
      end

      def package_dependencies
        deps = []

        # Database dependencies
        deps << "--depends postgresql" if @config[:database] == :postgresql
        deps << "--depends mysql-server" if @config[:database] == :mysql

        # Webserver dependencies
        webserver_deps = Detectors::Webserver.new(@app_path).system_dependencies
        webserver_deps.each { |dep| deps << "--depends #{dep}" }

        # Infrastructure dependencies
        infra_deps = Detectors::Infrastructure.new(@app_path).system_dependencies
        infra_deps.each { |dep| deps << "--depends #{dep}" }

				# SSL dependencies if enabled
        if @options[:ssl] && @config[:infrastructure][:webserver] != :standalone
          deps << "--depends certbot"
          deps << "--depends python3-certbot-nginx" if @config[:infrastructure][:webserver] == :nginx
          deps << "--depends python3-certbot-apache" if @config[:infrastructure][:webserver] == :apache
        end

        deps
      end
    end
  end
end