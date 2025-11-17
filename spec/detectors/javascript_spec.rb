require 'spec_helper'

RSpec.describe Goico::Detectors::Javascript do
  let(:detector) { described_class.new(app_path) }

  describe '#detect' do
    context 'with importmap' do
      let(:app_path) { create_temp_rails_app({
        'config/importmap.rb' => 'Rails.application.importmap.draw {}',
        'package.json' => nil
      }) }

      it 'detects importmap' do
        expect(detector.detect).to eq(:importmap)
      end
    end

    context 'with package.json but no importmap' do
      let(:app_path) { create_temp_rails_app({
        'config/importmap.rb' => nil,
        'package.json' => '{"name": "testapp"}'
      }) }

      it 'detects node' do
        expect(detector.detect).to eq(:node)
      end
    end

    context 'with webpack.config.js' do
      let(:app_path) { create_temp_rails_app({
        'config/importmap.rb' => nil,
        'package.json' => '{"name": "testapp"}',
        'webpack.config.js' => '// webpack config'
      }) }

      it 'detects webpack' do
        expect(detector.detect).to eq(:webpack)
      end
    end

    context 'with no JavaScript configuration' do
      let(:app_path) { create_temp_rails_app({
        'config/importmap.rb' => nil,
        'package.json' => nil,
        'webpack.config.js' => nil
      }) }

      it 'defaults to importmap' do
        expect(detector.detect).to eq(:importmap)
      end
    end
  end

  describe '#system_dependencies' do
    it 'returns empty for importmap' do
      allow(detector).to receive(:detect).and_return(:importmap)
      expect(detector.system_dependencies).to be_empty
    end

    it 'returns Node.js dependencies for node' do
      allow(detector).to receive(:detect).and_return(:node)
      deps = detector.system_dependencies
      expect(deps).to include('nodejs')
      expect(deps).to include('npm')
    end

    it 'returns Node.js dependencies for webpack' do
      allow(detector).to receive(:detect).and_return(:webpack)
      deps = detector.system_dependencies
      expect(deps).to include('nodejs')
      expect(deps).to include('npm')
    end
  end
end