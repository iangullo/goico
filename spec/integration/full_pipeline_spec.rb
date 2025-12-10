# spec/integration/full_pipeline_spec.rb
require "spec_helper"
require "tmpdir"
require "yaml"

RSpec.describe "Goico Full Pipeline Integration" do
  include IntegrationApp

  let(:tmp) { Dir.mktmpdir }
  let(:app_path) { "#{tmp}/rails_app" }
  let(:manifest_path) { "#{tmp}/goico-manifest.yml" }

  before do
    build_test_app!(app_path)
  end

  after do
    FileUtils.rm_rf(tmp)
  end

  it "generates a full manifest from analyzer" do
    analyzer = Goico::Analyzer::Base.new(app_path, ssl: true)
    manifest = analyzer.analyze

    expect(manifest[:app_path]).to eq(app_path)
    expect(manifest[:capabilities][:database]).to eq(:postgres)
    expect(manifest[:capabilities][:jobs]).to eq(:sidekiq)
    expect(manifest[:capabilities][:images]).to eq(:vips)
    expect(manifest[:capabilities][:app_server]).to eq(:puma)
    expect(manifest[:capabilities][:ssl]).to be(true)
  end
end
