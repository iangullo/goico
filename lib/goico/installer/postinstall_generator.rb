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

module Goico
  module Installer
    class PostinstallGenerator
      attr_reader :manifest

      def initialize(manifest)
        @manifest = manifest
      end

      def run
        Installer.info(I18n.t("goico.starting_verbose"))

        create_user_group
        set_permissions
        create_logs_tmp_dirs
        setup_database
        precompile_assets
        setup_secrets
        generate_webserver_configs
        generate_service_scripts
        generate_worker_service_scripts
        setup_ssl_certificates
        run_postinstall_scripts

        Installer.info(I18n.t("goico.success"))
      end

      private

      # --------------------
      # Helpers
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

      def app_server
        capabilities["app_server"] || "puma"
      end

      def domain
        capabilities["domain"]
      end

      def ssl_enabled?
        capabilities["ssl"] && domain
      end

      # --------------------
      # User & Group Creation
      # --------------------
      def create_user_group
        unless system("id -u #{app_user} > /dev/null 2>&1")
          Installer.info(I18n.t("goico.creating_user", user: app_user))
          system("groupadd #{app_group} 2>/dev/null || true")
          system("useradd -r -g #{app_group} -d #{app_path} -s /sbin/nologin #{app_user}")
        end
      end

      # --------------------
      # Permissions
      # --------------------
      def set_permissions
        Installer.info(I18n.t("goico.setting_permissions", path: app_path, user: app_user))
        FileUtils.chown_R(app_user, app_group, app_path)
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

      # --------------------
      # Database setup
      # --------------------
      def setup_database
        return unless capabilities["database"]

        Installer.info(I18n.t("goico.setup_database"))

        %w[db:create db:migrate].each do |cmd|
          full_cmd = "cd #{app_path} && sudo -u #{app_user} RAILS_ENV=production bundle exec rails #{cmd}"
          Installer.info(I18n.t("goico.running_command", command: full_cmd))
          system(full_cmd)
        end

        if capabilities["run_seeds"]
          full_cmd = "cd #{app_path} && sudo -u #{app_user} RAILS_ENV=production bundle exec rails db:seed"
          Installer.info(I18n.t("goico.running_command", command: full_cmd))
          system(full_cmd)
        else
          Installer.info(I18n.t("goico.skipping_seeds"))
        end
      end

      # --------------------
      # Assets precompilation & JS pinning
      # --------------------
      def precompile_assets
        return unless File.exist?(File.join(app_path, "config/application.rb"))

        Installer.info(I18n.t("goico.precompiling_assets"))

        commands = ["RAILS_ENV=production bundle exec rails assets:precompile"]
        js_backend = capabilities["javascript"]
        if %w[importmap esbuild].include?(js_backend.to_s)
          commands << "RAILS_ENV=production bundle exec rails importmap:pin_all"
        end

        commands.each do |cmd|
          full_cmd = "cd #{app_path} && sudo -u #{app_user} #{cmd}"
          Installer.info(I18n.t("goico.running_command", command: full_cmd))
          system(full_cmd)
        end
      end

      # --------------------
      # Rails credentials / secrets
      # --------------------
      def setup_secrets
        credentials_file = File.join(app_path, "config/credentials/production.key")
        return if File.exist?(credentials_file)

        Installer.info(I18n.t("goico.generating_secrets"))
        system("cd #{app_path} && sudo -u #{app_user} bin/rails credentials:edit --environment production")
      end

      # --------------------
      # Webserver config generation
      # --------------------
      def generate_webserver_configs
        require_relative "webserver_generator"
        WebserverGenerator.new(manifest: manifest, platform: RUBY_PLATFORM).generate
      end

      # --------------------
      # Worker service scripts
      # --------------------
      def generate_worker_service_scripts
        require_relative "worker_service_generator"
        WorkerServiceGenerator.new(manifest).generate_all
      end

      # --------------------
      # Application service scripts
      # --------------------
      def generate_service_scripts
        require_relative "service_generator"
        ServiceGenerator.new(manifest).generate_all
      end

      # --------------------
      # SSL certificate setup
      # --------------------
      def setup_ssl_certificates
        return unless ssl_enabled?

        Installer.info(I18n.t("goico.generating_ssl"))

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

        Installer.info(I18n.t("goico.generated_ssl"))
      end

      # --------------------
      # Optional postinstall scripts
      # --------------------
      def run_postinstall_scripts
        scripts_dir = File.join(app_path, "postinstall.d")
        return unless Dir.exist?(scripts_dir)

        Dir["#{scripts_dir}/*.sh"].sort.each do |script|
          Installer.info(I18n.t("goico.running_postinstall", path: script))
          system("sudo -u #{app_user} bash #{script}")
        end
      end
    end
  end
end