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

# lib/goico/installer/system_packages.rb
# SystemPackages - Resolve required OS packages from analyzed capabilities
module Goico
  module Installer
    class SystemPackages
      def self.resolve(capabilities)
        new(capabilities).all
      end

      def initialize(capabilities)
        @cap = capabilities.transform_keys(&:to_sym)
      end

      def all
        (
          base +
          app_server +
          database +
          jobs +
          images +
          javascript +
          webserver +
          ssl
        ).uniq
      end

      private

      # --------------------
      # Always required
      # --------------------
      def base
        %w[curl git ca-certificates]
      end

      # --------------------
      # App Server
      # --------------------
      def app_server
        case @cap[:app_server]
        when :puma
          %w[build-essential]
        when :passenger
          %w[libcurl4-openssl-dev]
        else
          []
        end
      end

      # --------------------
      # Database
      # --------------------
      def database
        case @cap[:database]
        when :postgres
          %w[postgresql-client libpq-dev]
        when :mysql
          %w[mysql-client libmysqlclient-dev]
        when :sqlite
          %w[sqlite3 libsqlite3-dev]
        else
          []
        end
      end

      # --------------------
      # Background Jobs
      # --------------------
      def jobs
        case @cap[:jobs]
        when :sidekiq, :resque
          %w[redis-server]
        when :solid_queue
          []
        else
          []
        end
      end

      # --------------------
      # Images
      # --------------------
      def images
        case @cap[:images]
        when :vips
          %w[libvips]
        when :mini_magick
          %w[imagemagick]
        else
          []
        end
      end

      # --------------------
      # JavaScript
      # --------------------
      def javascript
        case @cap[:javascript]
        when :webpack, :esbuild
          %w[nodejs]
        else
          []
        end
      end

      # --------------------
      # Webserver
      # --------------------
      def webserver
        case @cap[:webserver]
        when :nginx
          %w[nginx]
        when :apache
          %w[apache2]
        else
          []
        end
      end

      # --------------------
      # SSL
      # --------------------
      def ssl
        @cap[:ssl] ? %w[openssl] : []
      end
    end
  end
end
