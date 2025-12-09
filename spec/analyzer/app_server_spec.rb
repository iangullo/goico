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

# /spec/analyzer/app_server_spec.rb
require "tmpdir"
require_relative "../../lib/goico/analyzer/app_server"
require_relative "../../lib/goico/analyzer/gems"

RSpec.describe Goico::Analyzer::AppServer do
  let(:lock_with_puma) do
    <<~LOCK
      GEM
        specs:
          puma (6.4.0)
    LOCK
  end

  let(:lock_with_passenger) do
    <<~LOCK
      GEM
        specs:
          passenger (6.0.0)
    LOCK
  end

  it "detects puma when present in gems" do
    Dir.mktmpdir do |d|
      File.write(File.join(d, "Gemfile.lock"), lock_with_puma)
      gems = Goico::Analyzer::Gems.new(d)
      as = Goico::Analyzer::AppServer.new(gems)
      expect(as.type).to eq(:puma)
    end
  end

  it "detects passenger when present" do
    Dir.mktmpdir do |d|
      File.write(File.join(d, "Gemfile.lock"), lock_with_passenger)
      gems = Goico::Analyzer::Gems.new(d)
      as = Goico::Analyzer::AppServer.new(gems)
      expect(as.type).to eq(:passenger)
    end
  end

  it "returns :unknown when no server gem present" do
    Dir.mktmpdir do |d|
      File.write(File.join(d, "Gemfile.lock"), "GEM\n  specs:\n")
      gems = Goico::Analyzer::Gems.new(d)
      as = Goico::Analyzer::AppServer.new(gems)
      expect(as.type).to eq(:unknown)
    end
  end
end