# spec/integration/brew_package_spec.rb
require "spec_helper"
require "tmpdir"

RSpec.describe "Homebrew Packager Integration" do
  include IntegrationApp

  let(:tmp) { Dir.mktmpdir }
  let(:app_path) { "#{tmp}/rails_app" }

  let(:manifest) do
    {
      "app_path" => app_path,
      "capabilities" => {
        "app_name" => "brewapp",
        "version" => "0.1.0"
      }
    }
  end

  before do
    build_test_app!(app_path)
    allow_any_instance_of(Goico::Installer::PostinstallGenerator).to receive(:run)
    allow(File).to receive(:write)
  end

  it "creates a homebrew formula" do
    packager = Goico::Packager::Brew.new(manifest)

    packager.package(:brew)

    expect(File).to have_received(:write).with(/brewapp\.rb/, kind_of(String))
  end
end
