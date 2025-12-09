# spec/installer/postinstall_generator_spec.rb
# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Goico::Installer::PostinstallGenerator do
  let(:tmp_app) { Dir.mktmpdir }
  let(:manifest) do
    {
      "app_path" => tmp_app,
      "capabilities" => {
        "user" => "railsapp",
        "group" => "railsapp",
        "database" => "postgres",
        "ssl" => true,
        "domain" => "example.com",
        "run_seeds" => false
      }
    }
  end

  subject(:generator) { described_class.new(manifest) }

  before do
    FileUtils.mkdir_p(File.join(tmp_app, "config"))
    File.write(File.join(tmp_app, "config/application.rb"), "# rails")

    allow(Goico::Installer).to receive(:info)
    allow(generator).to receive(:system).and_return(true)

    stub_const("Goico::Installer::WebserverGenerator", Class.new do
      def initialize(**); end
      def generate; end
    end)

    stub_const("Goico::Installer::ServiceGenerator", Class.new do
      def initialize(*); end
      def generate_all; end
    end)

    stub_const("Goico::Installer::WorkerServiceGenerator", Class.new do
      def initialize(*); end
      def generate_all; end
    end)
  end

  after { FileUtils.remove_entry(tmp_app) }

  describe "#run" do
    it "executes the full postinstall workflow" do
      expect(generator).to receive(:create_user_group)
      expect(generator).to receive(:set_permissions)
      expect(generator).to receive(:create_logs_tmp_dirs)
      expect(generator).to receive(:setup_database)
      expect(generator).to receive(:precompile_assets)
      expect(generator).to receive(:generate_webserver_configs)
      expect(generator).to receive(:generate_service_scripts)
      expect(generator).to receive(:generate_worker_service_scripts)
      expect(generator).to receive(:setup_ssl_certificates)
      expect(generator).to receive(:run_postinstall_scripts)

      generator.run
    end
  end

  describe "#create_user_group" do
    it "creates user and group if missing" do
      expect(generator).to receive(:system)
        .with("id -u railsapp > /dev/null 2>&1")
        .and_return(false)

      expect(generator).to receive(:system)
        .with("groupadd railsapp 2>/dev/null || true")

      expect(generator).to receive(:system)
        .with("useradd -r -g railsapp -d #{tmp_app} -s /sbin/nologin railsapp")

      generator.send(:create_user_group)
    end
  end

  describe "#create_logs_tmp_dirs" do
    it "creates and sets permissions on log and tmp folders" do
      generator.send(:create_logs_tmp_dirs)

      %w[log tmp tmp/pids tmp/cache tmp/sockets].each do |dir|
        expect(Dir.exist?(File.join(tmp_app, dir))).to be(true)
      end
    end
  end

  describe "#setup_database" do
    it "runs db:create and db:migrate but skips db:seed by default" do
      expect(generator).to receive(:system)
        .with(/rails db:create/)
      expect(generator).to receive(:system)
        .with(/rails db:migrate/)
      expect(generator).not_to receive(:system)
        .with(/rails db:seed/)

      generator.send(:setup_database)
    end

    it "runs db:seed when enabled" do
      manifest["capabilities"]["run_seeds"] = true

      expect(generator).to receive(:system).with(/rails db:seed/)
      generator.send(:setup_database)
    end
  end

  describe "#precompile_assets" do
    it "runs asset precompilation when Rails app detected" do
      expect(generator).to receive(:system)
        .with(/rails assets:precompile/)

      generator.send(:precompile_assets)
    end
  end

  describe "#setup_ssl_certificates" do
    it "generates certificates when enabled" do
      allow(File).to receive(:exist?).and_return(false)

      expect(generator).to receive(:system)
        .with(/openssl req/)

      generator.send(:setup_ssl_certificates)
    end
  end

  describe "#run_postinstall_scripts" do
    it "executes custom scripts if present" do
      scripts_dir = File.join(tmp_app, "postinstall.d")
      FileUtils.mkdir_p(scripts_dir)

      script = File.join(scripts_dir, "01-custom.sh")
      File.write(script, "echo hello")

      expect(generator).to receive(:system)
        .with("sudo -u railsapp bash #{script}")

      generator.send(:run_postinstall_scripts)
    end
  end
end
