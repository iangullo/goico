# spec/analyzer/database_spec.rb
require "tmpdir"
require_relative "../../lib/goico/analyzer/database"
require_relative "../../lib/goico/analyzer/gems"

RSpec.describe Goico::Analyzer::Database do
  it "detects postgres (pg gem)" do
    Dir.mktmpdir do |d|
      File.write(File.join(d, "Gemfile.lock"), "GEM\n    specs:\n      pg (1.4.0)\n")
      gems = Goico::Analyzer::Gems.new(d)
      db = Goico::Analyzer::Database.new(gems)
      expect(db.type).to eq(:postgres)
    end
  end

  it "detects mysql (mysql2 gem)" do
    Dir.mktmpdir do |d|
      File.write(File.join(d, "Gemfile.lock"), "GEM\n    specs:\n      mysql2 (0.5.4)\n")
      gems = Goico::Analyzer::Gems.new(d)
      db = Goico::Analyzer::Database.new(gems)
      expect(db.type).to eq(:mysql)
    end
  end

  it "detects sqlite (sqlite3 gem)" do
    Dir.mktmpdir do |d|
      File.write(File.join(d, "Gemfile.lock"), "GEM\n    specs:\n      sqlite3 (1.4.2)\n")
      gems = Goico::Analyzer::Gems.new(d)
      db = Goico::Analyzer::Database.new(gems)
      expect(db.type).to eq(:sqlite)
    end
  end

  it "returns :unknown if none found" do
    Dir.mktmpdir do |d|
      File.write(File.join(d, "Gemfile.lock"), "GEM\n    specs:\n")
      gems = Goico::Analyzer::Gems.new(d)
      db = Goico::Analyzer::Database.new(gems)
      expect(db.type).to eq(:unknown)
    end
  end
end
