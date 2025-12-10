# spec/integration/rpm_package_spec.rb
RSpec.describe "RPM Packager Integration" do
  include IntegrationApp

  let(:tmp) { Dir.mktmpdir }
  let(:app_path) { "#{tmp}/rails_app" }

  let(:manifest) do
    {
      "app_path" => app_path,
      "capabilities" => {
        "app_name" => "rpmapp",
        "version" => "3.0.0",
        "database" => "mysql"
      }
    }
  end

  before do
    build_test_app!(app_path)
    allow_any_instance_of(Goico::Installer::PostinstallGenerator).to receive(:run)
  end

  it "invokes fpm for rpm" do
    packager = Goico::Packager::FPM::Base.new(manifest)

    expect(packager).to receive(:system).with(/fpm .* -t rpm/)

    packager.package(:rpm)
  end
end
