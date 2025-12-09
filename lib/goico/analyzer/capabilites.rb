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

# lib/goico/analyzer/capabilities.rb
#  - Manage manifest of Capabilities the Rails application requires.
module Goico
  module Analyzer
    class Capabilities
      def initialize(app_server:, database:, gems:, webserver:, options:)
        @app_server = app_server
        @database   = database
        @gems       = gems
        @webserver  = webserver
        @options    = options
      end

      def to_h
        {
          ruby:        RUBY_VERSION,
          app_server:  @app_server.type,
          database:    @database.type,
          run_seeds:   detect_run_seeds,
          jobs:        detect_jobs,
          storage:     detect_storage,
          javascript:  detect_javascript,
          images:      detect_images,
          css:         detect_css,
          webserver:   @webserver.type,
          ssl:         @options[:ssl] || false
        }
      end

      private

      def detect_run_seeds
        return true if @options[:run_seeds] == true
        false
      end

      def detect_jobs
        return :sidekiq if @gems.include?("sidekiq")
        return :solid_queue if @gems.include?("solid_queue")
        return :resque if @gems.include?("resque")
        :none
      end

      def detect_storage
        return :s3 if @gems.include?("aws-sdk-s3")
        return :gcs if @gems.include?("google-cloud-storage")
        :local
      end

      def detect_javascript
        return :webpack if @gems.include?("webpacker")
        return :esbuild if @gems.include?("esbuild")
        :importmap
      end

      def detect_images
        return :vips if @gems.include?("ruby-vips")
        return :mini_magick if @gems.include?("mini_magick")
        :none
      end

      def detect_css
        return :tailwind if @gems.include?("tailwindcss-rails")
        return :bootstrap if @gems.include?("bootstrap")
        :none
      end
    end
  end
end
