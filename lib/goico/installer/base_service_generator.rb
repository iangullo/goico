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

# lib/goico/installer/base_service_generator.rb
#
# Abstraction to generate service scripts for Rails applications
# - Supports systemd, init.d, launchd
# - Supports Puma or Passenger
require "fileutils"
require "erb"

module Goico
  module Installer
    class BaseServiceGenerator
      TEMPLATE_PATH = File.expand_path("../templates", __dir__)

      attr_reader :manifest, :platform, :service_type

      def initialize(manifest, platform: Installer::Platform.detect)
        @manifest = manifest
        @platform = platform
        @service_type = self.class.name.split("::").last.gsub("Generator", "").downcase.to_sym
      end

      # --------------------
      # Unified generation
      # --------------------
      # @param to_shell [Boolean] if true, returns shell commands instead of writing files
      def generate(to_shell: false)
        cmds = []

        units.each do |unit|
          cmds << generate_unit(**unit.merge(to_shell: to_shell))
        end

        cmds.compact.join("\n")
      end

      private

      # --------------------
      # List of units to generate
      # Should be defined in subclass as array of hashes:
      # [{ system: "systemd", path: "/etc/systemd/system/app.service", chmod: "755" }, ...]
      # --------------------
      def units
        raise NotImplementedError, "#{self.class} must define #units"
      end

      # --------------------
      # Unit generation helper
      # --------------------
      def generate_unit(system:, path:, to_shell:, chmod: nil)
        content = render_template(system)

        if to_shell
          cmd = +"cat > #{path} <<'EOF'\n#{content}\nEOF"
          cmd << "\nchmod #{chmod} #{path}" if chmod
          cmd
        else
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
          FileUtils.chmod(chmod.to_i(8), path) if chmod
          Installer.info("goico.generated_service", path: path)
          nil
        end
      end

      # --------------------
      # Render template
      # --------------------
      def render_template(system)
        template_file = File.join(TEMPLATE_PATH, template_filename(system))
        template = File.read(template_file)
        ERB.new(template, trim_mode: "-").result(binding)
      end

      # --------------------
      # Map system to template filename
      # Should be implemented in subclass
      # --------------------
      def template_filename(system)
        raise NotImplementedError, "#{self.class} must define #template_filename"
      end

      # --------------------
      # Helpers for templates
      # --------------------
      def app_path
        manifest["app_path"] || "/opt/rails_app"
      end

      def app_user
        manifest.dig("capabilities", "user") || "railsapp"
      end

      def app_group
        manifest.dig("capabilities", "group") || app_user
      end
    end
  end
end
