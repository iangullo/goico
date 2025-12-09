require "spec_helper"
require "goico/packager/fpm/base"
require "tmpdir"

RSpec.describe Goico::Packager::FPM::Base do
  let(:manifest) { { "app_name" => "demo", "app_path" => Dir.mktmpdir, "capabilities" => {} } }
  let(:klass) do
    Class.new(Goico::Packager::FPM::Base) do
      TYPE = "deb"
    end
  end

  it "builds via fpm command" do
    instance = klass.new(manifest)
    allow(Goico::Installer).to receive(:info)
    allow_any_instance_of(klass).to receive(:system).and_return(true)
    expect(instance.build).to be_truthy
  end
end
