require 'spec_helper'

RSpec.describe Goico::Generators::Base do
  let(:app_path) { create_temp_rails_app }
  let(:config) { { app_name: 'testapp' } }
  let(:options) { { type: 'deb' } }
  let(:generator) { described_class.new(app_path, config, options) }

  describe '#app_name' do
    it 'returns the app name from config' do
      expect(generator.app_name).to eq('testapp')
    end
  end

  describe 'path helpers' do
    it 'returns install prefix based on package type' do
      expect(generator.install_prefix).to eq('/usr')

      generator_with_brew = described_class.new(app_path, config, { type: 'brew' })
      expect(generator_with_brew.install_prefix).to eq('/usr/local')
    end

    it 'returns app install path' do
      expect(generator.app_install_path).to eq('/usr/share/testapp')
    end

    it 'returns config install path' do
      expect(generator.config_install_path).to eq('/etc/testapp')

      generator_with_brew = described_class.new(app_path, config, { type: 'brew' })
      expect(generator_with_brew.config_install_path).to eq('/usr/local/etc/testapp')
    end

    it 'returns log path' do
      expect(generator.log_path).to eq('/var/log/testapp')
    end

    it 'returns run path' do
      expect(generator.run_path).to eq('/var/run/testapp')
    end
  end

  describe '#say' do
    it 'outputs translated messages' do
      output = capture_stdout do
        generator.send(:say, 'cli.banner')
      end

      expect(output).to include('Usage:')
    end

    it 'handles variables in messages' do
      output = capture_stdout do
        generator.send(:say, 'cli.success', path: '/test.pkg')
      end

      expect(output).to include('/test.pkg')
    end
  end
end