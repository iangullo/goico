# spec/installer/service_generator_spec.rb
require "spec_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/goico/installer/service_generator"

RSpec.describe Goico::Installer::ServiceGenerator do
  let(:tmp_path) { Dir.mktmpdir }
  let(:manifest) do
    {
      "app_name" => "testapp",
      "app_path" => tmp_path,
      "capabilities" => {
        "user" => "testuser",
        "group" => "testgroup",
        "app_server" => "puma"
      }
    }
  end

  subject { described_class.new(manifest) }

  after { FileUtils.remove_entry(tmp_path) }

  describe "#generate_all" do
    it "generates systemd/initd/launchd scripts if supported" do
      allow(File).to receive(:exist?).and_return(true)
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
      expect(File).to receive(:write).at_least(:once)
      subject.generate_all
    end
  end
end
