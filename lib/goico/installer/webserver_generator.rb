# Goico - Ruby gem to automate intaller package generation for Rails apps.
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

# lib/installer/webserver_generator.rb
#
# Generates webserver configuration for Rails apps
# - Supports nginx, apache, direct
# - Adds TLS configuration if requested
# - Lazy-loads ERB templates from installer/templates
#
require "erb"
require "fileutils"

module Goico
  module Installer
    class WebserverGenerator
      TEMPLATE_PATH = File.expand_path("../templates", __dir__)

      attr_reader :manifest, :platform, :output_path

      def initialize(manifest:, platform:, output_path: nil)
        @manifest = manifest
        @platform = platform
        @output_path = output_path || default_output_path
      end

      def generate
        Installer.info("goico.generating_webserver", server: webserver)

        if ssl_enabled? && domain.nil?
          Installer.warn("goico.ssl_missing_domain")
        end

        template = load_template
        config = ERB.new(template, trim_mode: "-").result(binding)
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, config)
        Installer.info("goico.generated_webserver", path: output_path)

        generate_direct_ssl_snippet if webserver == "direct" && ssl_enabled?
      end

      private

      # --------------------
      # ERB helper methods
      # --------------------
      def webserver
        capabilities["webserver"] || "direct"
      end

      def capabilities
        manifest["capabilities"] || {}
      end

      def domain
        capabilities["domain"]
      end

      def user
        capabilities["user"] || "railsapp"
      end

      def app_path
        manifest["app_path"] || "/opt/rails_app"
      end

      def ssl_enabled?
        capabilities["ssl"] && domain
      end

      # --------------------
      # Paths and templates
      # --------------------
      def default_output_path
        name = manifest["app_name"] || "rails_app"
        case webserver
        when "nginx" then "/etc/nginx/sites-available/#{name}"
        when "apache" then "/etc/apache2/sites-available/#{name}.conf"
        else "./#{name}_direct.conf"
        end
      end

      def load_template
        file = case webserver
               when "nginx" then "nginx.conf.erb"
               when "apache" then "apache.conf.erb"
               else "direct.conf.erb"
               end
        path = File.join(TEMPLATE_PATH, file)
        raise IOError, Installer.t("goico.errors.missing_template", path: path) unless File.exist?(path)

        File.read(path)
      end

      # --------------------
      # Generate Puma SSL snippet for direct mode
      # --------------------
      def generate_direct_ssl_snippet
        snippet_dir = File.join(app_path, "config/puma")
        FileUtils.mkdir_p(snippet_dir)
        snippet_path = File.join(snippet_dir, "ssl_bind.rb")

        content = <<~RUBY
          # Auto-generated Puma SSL binding
          if Rails.env.production?
            ssl_bind '0.0.0.0', 443, {
              key: "/etc/ssl/private/#{domain}.key",
              cert: "/etc/ssl/certs/#{domain}.crt",
              verify_mode: "none"
            }
          end
        RUBY

        File.write(snippet_path, content)
        Installer.info("goico.generated_ssl_snippet", path: snippet_path)
      end
    end
  end
end
