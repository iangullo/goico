# Copyright (C) 2025  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
# frozen_string_literal: true

# lib/goico/installer/postinstall_generator.rb
#
# Full postinstall generator for Rails applications
# Responsibilities:
#  - Dedicated user/group creation
#  - Ownership & permissions
#  - Database setup/migrations/seeding
#  - Asset precompilation
#  - Logs/tmp directories creation
#  - Webserver configuration generation
#  - Service scripts generation (systemd, initd, launchd)
#  - TLS/SSL setup if requested
#  - Optional postinstall scripts
#
require "fileutils"
require_relative "service_generator"
require_relative "worker_service_generator"
require_relative "webserver_generator"

module Goico
  module Installer
    class PostinstallGenerator
      attr_reader :manifest, :platform

      def initialize(manifest)
        @manifest = manifest
        @platform = Installer::Platform.detect(manifest["capabilities"])
      end

      # --------------------
      # Run full installation
      # --------------------
      def run
        Installer.info("goico.starting_verbose")

        create_user_group
        set_permissions
        create_logs_tmp_dirs
        setup_database
        precompile_assets
        setup_secrets
        setup_ssl_certificates

        generate_webserver_configs
        generate_service_scripts
        generate_worker_service_scripts

        run_postinstall_scripts

        Installer.info("goico.success")
      end

      # --------------------
      # Render shell script version
      # --------------------
      def render_script
        <<~SH
          #!/bin/bash
          set -e

          #{user_group_script}
          #{permissions_script}
          #{logs_tmp_dirs_script}
          #{database_script}
          #{assets_script}
          #{secrets_script}
          #{ssl_script}
          #{webserver_script}
          #{service_script}
          #{worker_service_script}
          #{postinstall_scripts_shell}
        SH
      end

      private

      # --------------------
      # Helpers / capabilities
      # --------------------
      def capabilities
        manifest["capabilities"] || {}
      end

      def app_path
        manifest["app_path"] || "/opt/rails_app"
      end

      def app_user
        capabilities["user"] || "railsapp"
      end

      def app_group
        capabilities["group"] || app_user
      end

      def domain
        capabilities["domain"]
      end

      def ssl_enabled?
        capabilities["ssl"] && domain
      end

      # --------------------
      # User & group creation
      # --------------------
      def create_user_group
        return if system("id -u #{app_user} >/dev/null 2>&1")

        Installer.info("goico.creating_user", user: app_user)
        system("groupadd #{app_group} 2>/dev/null || true")
        system("useradd -r -g #{app_group} -d #{app_path} -s /sbin/nologin #{app_user}")
      end

      def user_group_script
        <<~SH
          if ! id -u #{app_user} >/dev/null 2>&1; then
            groupadd #{app_group} 2>/dev/null || true
            useradd -r -g #{app_group} -d #{app_path} -s /sbin/nologin #{app_user}
          fi
        SH
      end

      # --------------------
      # Permissions
      # --------------------
      def set_permissions
        Installer.info("goico.setting_permissions", path: app_path, user: app_user)
        FileUtils.chown_R(app_user, app_group, app_path)
      end

      def permissions_script
        "chown -R #{app_user}:#{app_group} #{app_path}"
      end

      # --------------------
      # Logs / tmp dirs
      # --------------------
      def create_logs_tmp_dirs
        %w[log tmp tmp/pids tmp/cache tmp/sockets].each do |dir|
          path = File.join(app_path, dir)
          FileUtils.mkdir_p(path)
          FileUtils.chown_R(app_user, app_group, path)
          FileUtils.chmod_R(0o755, path)
        end
      end

      def logs_tmp_dirs_script
        %w[log tmp tmp/pids tmp/cache tmp/sockets].map do |dir|
          path = File.join(app_path, dir)
          <<~SH
            mkdir -p #{path}
            chown -R #{app_user}:#{app_group} #{path}
            chmod -R 755 #{path}
          SH
        end.join("\n")
      end

      # --------------------
      # Database
      # --------------------
      def setup_database
        return unless capabilities["database"]

        Installer.info("goico.setup_database")
        %w[db:create db:migrate].each { |cmd| run_rails(cmd) }
        run_rails("db:seed") if capabilities["run_seeds"]
      end

      def database_script
        return "" unless capabilities["database"]

        script = <<~SH
          cd #{app_path}
          sudo -u #{app_user} RAILS_ENV=production bundle exec rails db:create
          sudo -u #{app_user} RAILS_ENV=production bundle exec rails db:migrate
        SH
        script << "\nsudo -u #{app_user} RAILS_ENV=production bundle exec rails db:seed" if capabilities["run_seeds"]
        script
      end

      # --------------------
      # Assets precompilation
      # --------------------
      def precompile_assets
        return unless File.exist?(File.join(app_path, "config/application.rb"))

        Installer.info("goico.precompiling_assets")
        run_rails("assets:precompile")
        run_rails("importmap:pin_all") if %w[importmap esbuild].include?(capabilities["javascript"].to_s)
      end

      def assets_script
        return "" unless File.exist?(File.join(app_path, "config/application.rb"))

        script = <<~SH
          cd #{app_path}
          sudo -u #{app_user} RAILS_ENV=production bundle exec rails assets:precompile
        SH
        if %w[importmap esbuild].include?(capabilities["javascript"].to_s)
          script << "\nsudo -u #{app_user} RAILS_ENV=production bundle exec rails importmap:pin_all"
        end
        script
      end

      # --------------------
      # Rails credentials
      # --------------------
      def setup_secrets
        credentials_file = File.join(app_path, "config/credentials/production.key")
        return if File.exist?(credentials_file)

        Installer.info("goico.generating_secrets")
        system("cd #{app_path} && sudo -u #{app_user} bin/rails credentials:edit --environment production")
      end

      def secrets_script
        credentials_file = File.join(app_path, "config/credentials/production.key")
        <<~SH
          if [ ! -f "#{credentials_file}" ]; then
            cd #{app_path}
            sudo -u #{app_user} bin/rails credentials:edit --environment production
          fi
        SH
      end

      # --------------------
      # SSL
      # --------------------
      def setup_ssl_certificates
        return unless ssl_enabled?

        Installer.info("goico.generating_ssl")
        cert_path = "/etc/ssl/certs/#{domain}.crt"
        key_path  = "/etc/ssl/private/#{domain}.key"

        unless File.exist?(cert_path) && File.exist?(key_path)
          system <<~CMD
            openssl req -x509 -nodes -days 365 \
              -subj "/CN=#{domain}" \
              -newkey rsa:2048 \
              -keyout #{key_path} \
              -out #{cert_path}
          CMD
          FileUtils.chmod(0o600, key_path)
          FileUtils.chmod(0o644, cert_path)
        end

        Installer.info("goico.generated_ssl")
      end

      def ssl_script
        return "" unless ssl_enabled?
        cert_path = "/etc/ssl/certs/#{domain}.crt"
        key_path  = "/etc/ssl/private/#{domain}.key"
        <<~SH
          if [ ! -f "#{cert_path}" ] || [ ! -f "#{key_path}" ]; then
            openssl req -x509 -nodes -days 365 \
              -subj "/CN=#{domain}" \
              -newkey rsa:2048 \
              -keyout "#{key_path}" \
              -out "#{cert_path}"
            chmod 600 "#{key_path}"
            chmod 644 "#{cert_path}"
          fi
        SH
      end

      # --------------------
      # Webserver
      # --------------------
      def generate_webserver_configs
        WebserverGenerator.new(manifest: manifest, platform: platform).generate
      end

      def webserver_script
        ""
      end

      # --------------------
      # Application service
      # --------------------
      def generate_service_scripts
        ServiceGenerator.new(manifest, platform: platform).generate
      end

      def service_script
        ""
      end

      # --------------------
      # Worker service
      # --------------------
      def generate_worker_service_scripts
        WorkerServiceGenerator.new(manifest).generate
      end

      def worker_service_script
        ""
      end

      # --------------------
      # Postinstall scripts
      # --------------------
      def run_postinstall_scripts
        scripts_dir = File.join(app_path, "postinstall.d")
        return unless Dir.exist?(scripts_dir)

        Dir["#{scripts_dir}/*.sh"].sort.each do |script|
          Installer.info("goico.running_postinstall", path: script)
          system("sudo -u #{app_user} bash #{script}")
        end
      end

      def postinstall_scripts_shell
        <<~SH
          if [ -d "#{app_path}/postinstall.d" ]; then
            for script in #{app_path}/postinstall.d/*.sh; do
              sudo -u #{app_user} bash "$script"
            done
          fi
        SH
      end

      # --------------------
      # Helpers
      # --------------------
      def run_rails(command)
        full_cmd = "cd #{app_path} && sudo -u #{app_user} RAILS_ENV=production bundle exec rails #{command}"
        Installer.info("goico.running_command", command: full_cmd)
        system(full_cmd)
      end
    end
  end
end

