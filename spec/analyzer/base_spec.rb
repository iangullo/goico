# spec/analyzer/base_spec.rb
require "tmpdir"
require_relative "../../lib/goico/analyzer/base"
require_relative "../../lib/goico/analyzer/gems"

RSpec.describe Goico::Analyzer::Base do
  it "produces a manifest hash with expected top-level keys" do
    Dir.mktmpdir do |d|
      # minimal Rails app skeleton
      FileUtils.mkdir_p(File.join(d, "config"))
      File.write(File.join(d, "config", "application.rb"), "# rails app")
      # write a Gemfile.lock with a few gems
      File.write(File.join(d, "Gemfile.lock"), "GEM\n  specs:\n    puma (6.4.0)\n    pg (1.4.0)\n")

      analyzer = Goico::Analyzer::Base.new(d, webserver: "nginx")
      manifest = analyzer.analyze

      expect(manifest).to be_a(Hash)
      expect(manifest["app_path"]).to eq(File.expand_path(d))
      expect(manifest["capabilities"]).to be_a(Hash)
      expect(manifest["capabilities"]["app_server"]).to eq(:puma)
      expect(manifest["capabilities"]["database"]).to eq(:postgres)
      expect(manifest["capabilities"]["webserver"]).to eq(:nginx)
    end
  end

  it "raises for non-rails path" do
    Dir.mktmpdir do |d|
      expect { Goico::Analyzer::Base.new(d).analyze }.to raise_error(RuntimeError)
    end
  end
end
