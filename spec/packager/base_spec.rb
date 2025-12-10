# spec/packager/base_spec.rb
require "spec_helper"
require "goico/packager/base"
require "fileutils"

RSpec.describe Goico::Packager::Base do
  let(:manifest) do
    {
      "app_path" => "/opt/rails_app",
      "capabilities" => { "app_name" => "myapp", "version" => "1.0.0" }
    }
  end
  let(:packager) { described_class.new(manifest) }

  before do
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp_r)
    allow(FileUtils).to receive(:rm_rf)
    stub_const("Goico::Installer::PostinstallGenerator", Class.new)
    allow_any_instance_of(Goico::Installer::PostinstallGenerator).to receive(:run)
    allow_any_instance_of(Goico::Installer::SystemPackages).to receive(:all).and_return(%w[curl git])
  end

  describe "#build" do
    it "prepares staging, copies files, runs postinstall, resolves dependencies, and calls package" do
      expect(packager).to receive(:package).with(:tar)
      packager.build(:tar)
    end
  end

  describe "#cleanup" do
    it "removes the staging directory" do
      expect(FileUtils).to receive(:rm_rf).with(packager.staging_dir)
      packager.send(:cleanup)
    end
  end
end

