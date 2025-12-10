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
require_relative "base_service_generator"

module Goico
  module Installer
    class WorkerServiceGenerator < BaseServiceGenerator
      private

      def units
        units = []
        if supported_systemd? then units << { system: "systemd", path: "/etc/systemd/system/#{manifest['app_name']}_worker.service" } end
        if supported_initd? then units << { system: "initd", path: "/etc/init.d/#{manifest['app_name']}_worker", chmod: "755" } end
        if supported_launchd? then units << { system: "launchd", path: File.expand_path("~/Library/LaunchAgents/#{manifest['app_name']}_worker.plist") } end
        units
      end

      def template_filename(system)
        "#{system}.worker.erb"
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
    end
  end
end
