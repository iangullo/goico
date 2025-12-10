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
require_relative "base_service_generator"

module Goico
  module Installer
    class ServiceGenerator < BaseServiceGenerator
      private

      def units
        name = manifest["app_name"] || "rails_app"
        init = manifest.dig("capabilities", "init_system") || "systemd"

        case init.to_s
        when "systemd"
          [{ system: "systemd", path: "/etc/systemd/system/#{name}.service" }]
        when "initd"
          [{ system: "initd", path: "/etc/init.d/#{name}", chmod: "755" }]
        when "launchd"
          [{ system: "launchd", path: "/Library/LaunchDaemons/#{name}.plist" }]
        else
          []
        end
      end

      def template_filename(system)
        app_server = manifest.dig("capabilities", "app_server") || "puma"
        case system.to_s
        when "systemd" then "systemd.#{app_server}.service.erb"
        when "initd" then "initd.#{app_server}.sh.erb"
        when "launchd" then "launchd.#{app_server}.plist.erb"
        else
          raise "Unknown system #{system}"
        end
      end
    end
  end
end
