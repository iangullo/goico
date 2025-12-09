# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Goico::Analyzer::Base do
  let(:tmp_app) { Dir.mktmpdir }

  before do
    # Minimal Rails structure
    FileUtils.mkdir_p(File.join(tmp_app, "config"))
    File.write(File.join(tmp_app, "config/application.rb"), "# rails app")

    # Fake Gemfile so gem analyzer doesn't crash
    File.write(File.join(tmp_app, "Gemfile"), <<~RUBY)
      source "https://rubygems.org"
      gem "rails"
      gem "pg"
    RUBY
  end

  after do
    FileUtils.remove_entry(tmp_app)
  end

  context "when --run-seeds is NOT provided" do
    it "sets run_seeds to false in the manifest" do
      analyzer = described_class.new(tmp_app, {})
      manifest = analyzer.analyze

      expect(manifest[:capabilities][:run_seeds]).to be(false)
    end
  end

  context "when --run-seeds IS provided" do
    it "sets run_seeds to true in the manifest" do
      analyzer = described_class.new(tmp_app, { run_seeds: true })
      manifest = analyzer.analyze

      expect(manifest[:capabilities][:run_seeds]).to be(true)
    end
  end

  context "when db/seeds.rb exists but flag not passed" do
    it "does NOT enable run_seeds automatically" do
      FileUtils.mkdir_p(File.join(tmp_app, "db"))
      File.write(File.join(tmp_app, "db/seeds.rb"), "# dev seeds")

      analyzer = described_class.new(tmp_app, {})
      manifest = analyzer.analyze

      expect(manifest[:capabilities][:run_seeds]).to be(false)
    end
  end
end
