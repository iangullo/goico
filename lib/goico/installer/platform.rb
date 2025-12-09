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

# lib/goico/installer/platform.rb
#
# Platform detection for system packages / installer
# Determines package manager and OS type
#
module Goico
  module Installer
    class Platform
      attr_reader :name, :version, :family

      # Detect platform automatically
      def self.detect(_capabilities = {})
        os_release = read_os_release
        family, name, version = parse_os_release(os_release)
        new(name: name, family: family, version: version)
      rescue
        # fallback: detect via uname
        uname = `uname -s`.strip
        new(name: uname.downcase.to_sym, family: uname.downcase.to_sym, version: "")
      end

      def initialize(name:, family:, version:)
        @name = name.to_sym
        @family = family.to_sym
        @version = version
      end

      # --------------------
      # Predicate helpers
      # --------------------
      def apt?
        %i[debian ubuntu].include?(@family)
      end

      def yum?
        %i[rhel centos rocky alma].include?(@family)
      end

      def brew?
        %i[macos darwin].include?(@family)
      end

      # --------------------
      # Internal helpers
      # --------------------
      def self.read_os_release
        path = "/etc/os-release"
        return {} unless File.exist?(path)

        File.read(path).lines.each_with_object({}) do |line, h|
          key, value = line.strip.split("=", 2)
          h[key] = value&.gsub(/^"|"$/, "") if key && value
        end
      end

      def self.parse_os_release(data)
        # Simple heuristic
        id = data["ID"] || "unknown"
        version = data["VERSION_ID"] || ""
        family = case id
                 when "ubuntu", "debian" then :debian
                 when "centos", "rhel", "rocky", "alma" then :rhel
                 else id.to_sym
                 end
        [family, id.to_sym, version]
      end
    end
  end
end
