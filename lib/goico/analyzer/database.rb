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

# lib/goico/analyzer/database.rb
#  - Determine wich database to use as backend for the application.
module Goico
  module Analyzer
    class Database
      attr_reader :type

      def initialize(gems)
        @gems = gems
        @type = detect
      end

      private

      def detect
        return :postgres if @gems.include?("pg")
        return :mysql if @gems.include?("mysql2")
        return :sqlite if @gems.include?("sqlite3")

        :unknown
      end
    end
  end
end
