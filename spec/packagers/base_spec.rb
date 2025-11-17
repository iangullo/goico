require 'spec_helper'

RSpec.describe Goico::Packagers::Base do
  let(:app_path) { create_temp_rails_app }
  let(:config) { {
    app_name: 'testapp',
    database: :postgresql,
    javascript: :importmap,
    infrastructure: { webserver: :nginx }
  } }
  let(:options) { { type: 'deb' } }
  let(:packager) { described_class.new(app_path, config, options) }

  describe '#build' do
    it 'raises NotImplementedError for abstract methods' do
      expect { packager.build }.to raise_error(NotImplementedError)
    end
  end

  describe 'protected methods' do
    it 'raises NotImplementedError for copy_application' do
      expect { packager.send(:copy_application) }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for generate_configurations' do
      expect { packager.send(:generate_configurations) }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for build_package' do
      expect { packager.send(:build_package) }.to raise_error(NotImplementedError)
    end
  end

  describe '#app_name' do
    it 'returns the app name from config' do
      expect(packager.send(:app_name)).to eq('testapp')
    end
  end

  describe '#say' do
    it 'outputs translated messages' do
      output = capture_stdout do
        packager.send(:say, 'cli.banner')
      end

      expect(output).to include('Usage:')
    end
  end
end