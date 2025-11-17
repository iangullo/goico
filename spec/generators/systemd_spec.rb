require 'spec_helper'

RSpec.describe Goico::Generators::Systemd do
  let(:app_path) { create_temp_rails_app }
  let(:config) { { app_name: 'testapp', database: :postgresql } }
  let(:options) { { type: 'deb', user: 'testuser' } }
  let(:generator) { described_class.new(app_path, config, options) }

  describe '#generate' do
    it 'creates a systemd service file' do
      output_path = File.join(app_path, 'config', 'deploy', 'testapp.service')

      expect {
        generator.generate
      }.to change { File.exist?(output_path) }.from(false).to(true)

      content = File.read(output_path)
      expect(content).to include('Description=Testapp Rails Application')
      expect(content).to include('User=testuser')
      expect(content).to include('WorkingDirectory=/usr/share/testapp')
    end

    it 'outputs success message' do
      output = capture_stdout { generator.generate }
      expect(output).to include('systemd service file generated')
    end
  end
end