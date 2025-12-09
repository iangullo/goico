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

# Base /lib/goico/manifest/validator.rb
#  - Validate Goico manifest files.
require "time"

module Goico
  module Manifest
    class ValidationError < StandardError; end

    class Validator
      REQUIRED_TOP_LEVEL = %w[app_path generated_at capabilities].freeze
      REQUIRED_CAPABILITY_KEYS = %w[
        ruby app_server database jobs storage javascript images css webserver ssl
      ].freeze

      # Validate a manifest Hash (parsed YAML -> Ruby Hash)
      # Raises ValidationError with a descriptive message on failure.
      def self.validate!(manifest)
        raise ValidationError, "manifest must be a Hash" unless manifest.is_a?(Hash)

        # Top-level required keys
        missing = REQUIRED_TOP_LEVEL - manifest.keys.map(&:to_s)
        unless missing.empty?
          raise ValidationError, "Missing top-level keys: #{missing.join(', ')}"
        end

        # generated_at is parseable timestamp
        begin
          Time.iso8601(manifest["generated_at"].to_s)
        rescue ArgumentError
          raise ValidationError, "generated_at must be a valid ISO8601 timestamp"
        end

        # capabilities presence and type
        caps = manifest["capabilities"]
        unless caps.is_a?(Hash)
          raise ValidationError, "capabilities must be a Hash"
        end

        missing_caps = REQUIRED_CAPABILITY_KEYS - caps.keys.map(&:to_s)
        unless missing_caps.empty?
          raise ValidationError, "Missing capability keys: #{missing_caps.join(', ')}"
        end

        # Validate types for a few keys
        unless caps["ssl"].is_a?(TrueClass) || caps["ssl"].is_a?(FalseClass)
          raise ValidationError, "capabilities.ssl must be boolean"
        end

        # app_server, database, webserver should be symbol-like strings or symbols
        %w[app_server database webserver].each do |k|
          v = caps[k]
          unless v.is_a?(String) || v.is_a?(Symbol)
            raise ValidationError, "capabilities.#{k} must be a String or Symbol"
          end
        end

        true
      end
    end
  end
end
