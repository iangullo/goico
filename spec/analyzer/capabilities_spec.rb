# spec/analyzer/capabilities_spec.rb
require "tmpdir"
require_relative "../../lib/goico/analyzer/capabilities"
require_relative "../../lib/goico/analyzer/gems"
require_relative "../../lib/goico/analyzer/app_server"
require_relative "../../lib/goico/analyzer/database"

RSpec.describe Goico::Analyzer::Capabilities do
  let(:lock_content) do
    <<~LOCK
      GEM
        specs:
          puma (6.4.0)
          pg (1.4.0)
          sidekiq (6.5.0)
          ruby-vips (2.0.0)
          webpacker (5.0.0)
          tailwindcss-rails (0.1.0)
    LOCK
  end

  it "aggregates capabilities correctly" do
    Dir.mktmpdir do |d|
      File.write(File.join(d, "Gemfile.lock"), lock_content)
      gems = Goico::Analyzer::Gems.new(d)
      app_server = Goico::Analyzer::AppServer.new(gems)
      database = Goico::Analyzer::Database.new(gems)
      webserver = OpenStruct.new(type: :nginx)
      caps = Goico::Analyzer::Capabilities.new(
        app_server: app_server,
        database: database,
        gems: gems,
        webserver: webserver,
        options: { ssl: true }
      )

      h = caps.to_h
      expect(h[:app_server]).to eq(:puma)
      expect(h[:database]).to eq(:postgres)
      expect(h[:jobs]).to eq(:sidekiq)
      expect(h[:images]).to eq(:vips)
      expect(h[:javascript]).to eq(:webpack)
      expect(h[:css]).to eq(:tailwind)
      expect(h[:webserver]).to eq(:nginx)
      expect(h[:ssl]).to be true
    end
  end
end
