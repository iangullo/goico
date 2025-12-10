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

# lib/goico/installer/base.rb
#
# Base module for installer generators
# - Lazy loads subcomponents
# - Provides helper methods
# - Integrates I18n.t for user-facing messages
#
module Goico
  module Installer
    autoload :Platform, "goico/installer/platform"
    autoload :PostinstallGenerator, "goico/installer/postinstall_generator"
    autoload :ServiceGenerator, "goico/installer/service_generator"
    autoload :WorkerServiceGenerator, "goico/installer/worker_service_generator"
    autoload :SystemPackages, "goico/installer/system_packages"
    autoload :Webserver, "goico/installer/webserver"

    # Helper: print a user message
    def self.info(key, **args)
      puts Goico::Core::I18nHelper.t(key, **args)
    end

    def self.warn(key, **args)
      puts Goico::Core::I18nHelper.t(key, **args)
    end

    # Resolve system packages for given platform and capabilities
    def self.resolve_system_packages(platform, capabilities)
      pkgs = SystemPackages.for(platform.name, capabilities)

      # Handle EPEL for yum if needed
      if platform.yum? && capabilities["images"].to_s == "vips"
        pkgs.unshift("epel-release") # ensure installed first
      end

      # Debian extra packages
      if platform.apt?
        pkgs.unshift(*%w[build-essential libssl-dev ruby-dev])
      end

      pkgs.uniq
    end
  end
end
