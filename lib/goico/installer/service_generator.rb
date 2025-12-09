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

# lib/goico/installer/service_generator.rb
#
# Generates service scripts for Rails applications
# - Supports systemd, init.d, launchd
# - Supports Puma or Passenger
# - Uses templates from lib/goico/installer/templates/
#
module Goico
  module Installer
    class ServiceGenerator
      attr_reader :platform, :capabilities, :manifest, :output_path, :service_type

      TEMPLATE_PATH = File.expand_path("../templates", __dir__)

      # @param manifest [Hash] Manifest from Analyzer
      # @param platform [Installer::Platform] Detected platform object
      # @param service_type [Symbol] :webapp or :worker
      # @param output_path [String] Path to write the service script
      def initialize(manifest:, platform:, service_type: :webapp, output_path: nil)
        @manifest = manifest
        @capabilities = manifest["capabilities"] || {}
        @platform = platform
        @service_type = service_type
        @output_path = output_path || default_output_path
      end

      # --------------------
      # Public API
      # --------------------
      def generate
        Installer.info("goico.generating_service", service: service_type)

        template = load_template
        script = ERB.new(template, trim_mode: "-").result(binding)

        File.write(output_path, script)
        Installer.info("goico.generated_service", path: output_path)
      end

      private

      def default_output_path
        name = manifest["app_name"] || "rails_app"
        case capabilities["init_system"].to_s
        when "systemd" then "/etc/systemd/system/#{name}.service"
        when "initd" then "/etc/init.d/#{name}"
        when "launchd" then "/Library/LaunchDaemons/#{name}.plist"
        else
          "./#{name}.service"
        end
      end

      # Load ERB template based on init system and app server
      def load_template
        init_system = capabilities["init_system"] || "systemd"
        app_server = capabilities["app_server"] || "puma"

        filename = case init_system.to_s
                   when "systemd"
                     "systemd.#{app_server}.service.erb"
                   when "initd"
                     "initd.#{app_server}.sh.erb"
                   when "launchd"
                     "launchd.#{app_server}.plist.erb"
                   else
                     raise ArgumentError,
                           Goico::Core::I18nHelper.t("goico.errors.invalid_init_system",
                                                     system: init_system,
                                                     valid: "systemd, initd, launchd")
                   end

        path = File.join(TEMPLATE_PATH, filename)
        unless File.exist?(path)
          raise IOError,
                Goico::Core::I18nHelper.t("goico.errors.missing_template", path: path)
        end

        File.read(path)
      end

      # Helper methods for ERB template
      def user
        capabilities["user"] || "railsapp"
      end

      def app_path
        manifest["app_path"] || "/opt/rails_app"
      end

      def ruby_bin
        capabilities["rbenv"] ? "/usr/bin/env ruby" : "/usr/bin/ruby"
      end
    end
  end
end