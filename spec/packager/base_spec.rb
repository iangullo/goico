require "spec_helper"
require "goico/packager/base"

RSpec.describe Goico::Packager::Base do
  let(:manifest) { { "app_name" => "demo", "app_path" => "/tmp/demo", "capabilities" => {} } }
  subject { described_class.new(manifest) }

  it "dispatches to deb builder" do
    allow_any_instance_of(Goico::Packager::Builders::Deb).to receive(:build).and_return(true)
    expect { subject.build("deb") }.not_to raise_error
  end

  it "raises on invalid target" do
    expect { subject.build("zip") }.to raise_error(ArgumentError)
  end
end
