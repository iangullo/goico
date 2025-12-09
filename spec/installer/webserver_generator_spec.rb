# spec/goico/installer/webserver_generator_spec.rb
require "spec_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/goico/installer/webserver_generator"

RSpec.describe Goico::Installer::WebserverGenerator do
  let(:tmp_path) { Dir.mktmpdir }
  let(:manifest) do
    {
      "app_name" => "testapp",
      "app_path" => tmp_path,
      "capabilities" => {
        "user" => "testuser",
        "domain" => "example.com",
        "ssl" => true
      }
    }
  end

  subject { described_class.new(manifest: manifest, platform: RUBY_PLATFORM) }

  after { FileUtils.remove_entry(tmp_path) }

  describe "#generate" do
    it "generates nginx, apache, direct configs" do
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
      expect(File).to receive(:write).at_least(:once)
      subject.generate
    end
  end
end
