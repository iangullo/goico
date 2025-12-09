it "extracts ruby version and deployment mode" do
  Dir.mktmpdir do |d|
    File.write(File.join(d, "Gemfile.lock"), <<~LOCK)
      GEM
        remote: https://rubygems.org/
        specs:
          puma (6.4.0)

      PLATFORMS
        ruby

      RUBY VERSION
         ruby 3.2.2p54

      DEPENDENCIES
        puma

      BUNDLED WITH
         2.4.10
    LOCK

    gems = Goico::Analyzer::Gems.new(d)

    expect(gems.ruby_version).to eq("ruby 3.2.2p54")
    expect(gems.deployment_mode).to eq("production")
  end
end
