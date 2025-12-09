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

# lib/goico/installer/worker_service_generator
#
# Generates background worker services for Rails applications
# Supports systemd, initd, launchd
#
require "fileutils"

module Goico
  module Installer
    class WorkerServiceGenerator
      attr_reader :manifest

      def initialize(manifest)
        @manifest = manifest
      end

      def generate_all
        generate_systemd if supported_systemd?
        generate_initd if supported_initd?
        generate_launchd if supported_launchd?
      end

      private

      def app_path
        manifest["app_path"] || "/opt/rails_app"
      end

      def app_user
        manifest.dig("capabilities", "user") || "railsapp"
      end

      def app_group
        manifest.dig("capabilities", "group") || app_user
      end

      def supported_systemd?
        File.exist?("/bin/systemctl") || File.exist?("/usr/bin/systemctl")
      end

      def supported_initd?
        File.directory?("/etc/init.d")
      end

      def supported_launchd?
        RUBY_PLATFORM.include?("darwin")
      end

      # --------------------
      # Templates paths
      # --------------------
      def template_path(system)
        File.join(__dir__, "templates", "#{system}.worker.erb")
      end

      # --------------------
      # Generation methods
      # --------------------
      def generate_systemd
        path = "/etc/systemd/system/#{manifest['app_name']}_worker.service"
        File.write(path, render_template("systemd"))
      end

      def generate_initd
        path = "/etc/init.d/#{manifest['app_name']}_worker"
        File.write(path, render_template("initd"))
        FileUtils.chmod(0o755, path)
      end

      def generate_launchd
        path = File.expand_path("~/Library/LaunchAgents/#{manifest['app_name']}_worker.plist")
        File.write(path, render_template("launchd"))
      end

      def render_template(system)
        template_file = template_path(system)
        template = File.read(template_file)
        ERB.new(template).result(binding)
      end
    end
  end
end
