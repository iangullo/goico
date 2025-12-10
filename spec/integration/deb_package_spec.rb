# spec/integration/deb_package_spec.rbrequire "spec_helper"
require "tmpdir"

RSpec.describe "DEB Packager Integration" do
  include IntegrationApp

  let(:tmp) { Dir.mktmpdir }
  let(:app_path) { "#{tmp}/rails_app" }

  let(:manifest) do
    {
      "app_path" => app_path,
      "capabilities" => {
        "app_name" => "debapp",
        "version" => "2.1.0",
        "database" => "postgres",
        "webserver" => "nginx",
        "jobs" => "sidekiq",
        "ssl" => true
      }
    }
  end

  before do
    build_test_app!(app_path)
    allow_any_instance_of(Goico::Installer::PostinstallGenerator).to receive(:run)
  end

  it "invokes fpm for deb" do
    packager = Goico::Packager::FPM::Base.new(manifest)

    expect(packager).to receive(:system).with(/fpm .* -t deb/)

    packager.package(:deb)
  end
end
