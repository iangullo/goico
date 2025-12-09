# spec/installer/worker_service_generator_spec.rb
require "spec_helper"
require "tmpdir"
require_relative "../../lib/goico/installer/worker_service_generator"

RSpec.describe Goico::Installer::WorkerServiceGenerator do
  let(:tmp_path) { Dir.mktmpdir }
  let(:manifest) do
    {
      "app_name" => "testapp",
      "app_path" => tmp_path,
      "capabilities" => { "user" => "testuser", "group" => "testgroup" }
    }
  end

  subject { described_class.new(manifest) }

  after { FileUtils.remove_entry(tmp_path) }

  describe "#generate_all" do
    it "generates all worker service templates" do
      allow(FileUtils).to receive(:chmod)
      allow(File).to receive(:write)
      expect(File).to receive(:write).at_least(:once)
      subject.generate_all
    end
  end
end
