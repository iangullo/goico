# spec/packager/tar_spec.rb
require "spec_helper"
require "goico/packager/tar"
require "fileutils"

RSpec.describe Goico::Packager::Tar do
  let(:manifest) { { "app_path" => "/opt/rails_app", "capabilities" => { "app_name" => "myapp" } } }
  let(:packager) { described_class.new(manifest) }

  before do
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp_r)
    allow(FileUtils).to receive(:rm_rf)
  end

  describe "#package" do
    it "creates a tar.gz package in staging dir" do
      expect(packager).to receive(:system).with(/tar czf .*\.tar\.gz \./)
      packager.send(:package, :tar)
    end
  end
end
