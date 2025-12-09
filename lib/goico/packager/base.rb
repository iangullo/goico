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
# Base module for package generators
# - Lazy loads subcomponents
# - Provides helper methods
# - Integrates I18n.t for user-facing messages
#
module Goico
  module Packager
    class Base
      attr_reader :manifest, :staging_dir

      def initialize(manifest)
        @manifest = manifest
        @staging_dir = "/tmp/goico_build_#{Time.now.to_i}"
      end

      # Entry point for all builders
      def build(target)
        prepare_staging
        copy_app_files
        generate_postinstall
        resolve_dependencies
        package(target)
      ensure
        cleanup
      end

      private

      def prepare_staging
        FileUtils.mkdir_p(staging_dir)
      end

      def copy_app_files
        FileUtils.cp_r("#{manifest['app_path']}/.", staging_dir)
      end

      def generate_postinstall
        Goico::Installer::PostinstallGenerator.new(manifest).run
      end

      def resolve_dependencies
        @dependencies = Goico::Installer::SystemPackages.new(manifest['capabilities']).all
      end

      def package(target)
        raise NotImplementedError, "Package method must be implemented in subclass"
      end

      def cleanup
        FileUtils.rm_rf(staging_dir)
      end
    end
  end
end
