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

# AppServer /lib/goico/analyzer/app_server.rb
#  - Determine the rails server that runs the application
module Goico
  module Analyzer
    class AppServer
      attr_reader :type

      def initialize(gems)
        @gems = gems
        @type = detect
      end

      private

      def detect
        return :passenger if @gems.include?("passenger")
        return :puma if @gems.include?("puma")

        :unknown
      end
    end
  end
end
