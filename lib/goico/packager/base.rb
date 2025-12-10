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

# lib/goico/packager/base.rb
#
# Base class for packaging Rails apps with Goico
# Responsibilities:
#  - Manage staging directory
#  - Pull app metadata from manifest
#  - Generate postinstall script
#  - Resolve dependencies via SystemPackages
#  - Provide helper methods for FPM, Brew, and Tar builders
#
module Goico
  module Packager
    class Base
      attr_reader :manifest, :staging_dir, :dependencies

      def initialize(manifest)
        @manifest = manifest
        @staging_dir = "/tmp/#{manifest['capabilities']['app_name']}_pkg"
        @dependencies = []
      end

      def prepare_dependencies
        require_relative "../installer/system_packages"
        @dependencies = Installer::SystemPackages.resolve(manifest["capabilities"])
      end

      def postinstall_script
        require_relative "../installer/postinstall_generator"
        PostinstallGenerator.new(manifest).render_script
      end

      def clean_staging
        FileUtils.rm_rf(staging_dir)
        FileUtils.mkdir_p(staging_dir)
      end

      private

      def capabilities
        manifest["capabilities"] || {}
      end

      def app_name
        capabilities["app_name"]
      end

      def app_version
        capabilities["version"]
      end

      def app_description
        capabilities["description"] || ""
      end

      def app_homepage
        capabilities["homepage"] || ""
      end

      def app_license
        capabilities["license"] || "MIT"
      end

      def maintainer
        capabilities["maintainer"] || "Unknown <unknown@example.com>"
      end
    end
  end
end
