require "spec_helper"
require "goico/packager/fpm"

RSpec.describe Goico::Packager::FPM::Base do
  let(:manifest) { { "capabilities" => { "app_name" => "myapp", "version" => "1.0.0" } } }
  let(:packager) { described_class.new(manifest) }

  before do
    stub_const("Goico::Installer::PostinstallGenerator", Class.new)
    allow_any_instance_of(Goico::Installer::PostinstallGenerator).to receive(:run)
    allow_any_instance_of(Goico::Installer::SystemPackages).to receive(:all).and_return(%w[curl git])
    allow(packager).to receive(:system)
  end

  describe "#package" do
    it "calls build_deb for :deb" do
      expect(packager).to receive(:build_deb)
      packager.package(:deb)
    end

    it "calls build_rpm for :rpm" do
      expect(packager).to receive(:build_rpm)
      packager.package(:rpm)
    end

    it "raises error for unsupported target" do
      expect { packager.package(:tar) }.to raise_error(RuntimeError)
    end
  end
end
