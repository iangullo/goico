# spec/integration/tar_package_spec.rb
require "spec_helper"
require "tmpdir"

RSpec.describe "TAR Packager Integration" do
  include IntegrationApp

  let(:tmp) { Dir.mktmpdir }
  let(:app_path) { "#{tmp}/rails_app" }
  let(:manifest) do
    {
      "app_path" => app_path,
      "capabilities" => {
        "app_name" => "tarapp",
        "version" => "1.0.0",
        "database" => "postgres",
        "app_server" => "puma",
        "javascript" => "importmap"
      }
    }
  end

  before do
    build_test_app!(app_path)
    allow_any_instance_of(Goico::Installer::PostinstallGenerator).to receive(:run)
  end

  it "builds a tar.gz archive" do
    packager = Goico::Packager::Tar.new(manifest)

    allow(packager).to receive(:system).and_return(true)

    output = packager.build(:tar)

    expect(packager).to have_received(:system).with(/tar czf .*\.tar\.gz/)
  end
end
