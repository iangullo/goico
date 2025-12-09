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

# lib/goico/analyzer/base.rb
#  - Analyze rails application code to determine definition of components
require "yaml"

require_relative "gems"
require_relative "app_server"
require_relative "database"
require_relative "capabilities"

module Goico
  module Analyzer
    class Base
      def initialize(app_path, options = {})
        @app_path = File.expand_path(app_path)
        @options  = options
      end

      def analyze
        raise "Invalid Rails application path" unless rails_app?

        gems       = Gems.new(@app_path)
        app_server = AppServer.new(gems)
        database   = Database.new(gems)
        webserver  = detect_webserver

        capabilities = Capabilities.new(
          app_server: app_server,
          app_path: @app_path,
          database: database,
          gems: gems,
          webserver: webserver,
          options: @options
        )

        build_manifest(capabilities)
      end

      private

      def rails_app?
        File.exist?(File.join(@app_path, "config", "application.rb"))
      end

      def detect_webserver
        case @options[:webserver]
        when "nginx"   then OpenStruct.new(type: :nginx)
        when "apache"  then OpenStruct.new(type: :apache)
        else                OpenStruct.new(type: :direct)
        end
      end

      def build_manifest(capabilities)
        {
          app_path:     @app_path,
          generated_at: Time.now.utc.iso8601,
          capabilities: capabilities.to_h
        }
      end
    end
  end
end
