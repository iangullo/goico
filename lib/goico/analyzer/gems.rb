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

# Gems /lib/goico/analyzer/gems.rb
#  - Determine wich ruby gems to attach for the application
require "bundler"

module Goico
  module Analyzer
    class Gems
      attr_reader :path, :specs, :ruby_version, :deployment_mode

      def initialize(path)
        @path = path
        lockfile = File.join(path, "Gemfile.lock")

        unless File.exist?(lockfile)
          raise "Gemfile.lock not found at #{lockfile}"
        end

        parsed = Bundler::LockfileParser.new(File.read(lockfile))

        @specs = parsed.specs.each_with_object({}) do |spec, h|
          h[spec.name] = spec.version.to_s
        end

        # ✅ Ruby version (if declared)
        @ruby_version = parsed.ruby_version&.strip

        # ✅ Force production mode (we never infer dev/test)
        @deployment_mode = "production"
      end

      def include?(gem_name)
        specs.key?(gem_name)
      end

      def version(gem_name)
        specs[gem_name]
      end

      def all
        specs.dup
      end
    end
  end