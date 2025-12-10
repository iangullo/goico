# spec/packager/brew_spec.rb
require "spec_helper"
require "goico/packager/brew"
require "erb"

RSpec.describe Goico::Packager::Brew do
  let(:manifest) { { "capabilities" => { "app_name" => "myapp" } } }
  let(:packager) { described_class.new(manifest) }
  let(:template_path) { File.join(__dir__, "../../lib/goico/packager/templates/brew.rb.erb") }

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:write)
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp_r)
    allow(FileUtils).to receive(:rm_rf)
    stub_const("Goico::Installer::PostinstallGenerator", Class.new)
    allow_any_instance_of(Goico::Installer::PostinstallGenerator).to receive(:run)
    allow_any_instance_of(Goico::Installer::SystemPackages).to receive(:all).and_return([])
  end

  describe "#package" do
    it "renders the ERB template and writes Homebrew formula" do
      expect(File).to receive(:write).with(/\.rb$/, kind_of(String))
      packager.send(:package, :brew)
    end
  end
end
