require 'spec_helper'

RSpec.describe Goico::Detectors::Webserver do
  let(:detector) { described_class.new(app_path) }

  describe '#detect' do
    context 'with nginx config' do
      let(:app_path) { create_temp_rails_app('config/nginx.conf' => '# nginx config') }

      it 'detects nginx' do
        expect(detector.detect).to eq(:nginx)
      end
    end

    context 'with apache config' do
      let(:app_path) { create_temp_rails_app('config/apache.conf' => '# apache config') }

      it 'detects apache' do
        expect(detector.detect).to eq(:apache)
      end
    end

    context 'with puma config' do
      let(:app_path) { create_temp_rails_app({
        'config/puma.rb' => '# puma config',
        'config/nginx.conf' => nil
      }) }

      it 'detects standalone' do
        expect(detector.detect).to eq(:standalone)
      end
    end

    context 'with no specific config' do
      let(:app_path) { create_temp_rails_app({
        'config/nginx.conf' => nil,
        'config/apache.conf' => nil,
        'config/puma.rb' => nil
      }) }

      it 'defaults to nginx' do
        expect(detector.detect).to eq(:nginx)
      end
    end

    context 'with explicit option' do
      let(:app_path) { create_temp_rails_app }
      let(:detector) { described_class.new(app_path, webserver: 'apache') }

      it 'uses the explicit option' do
        expect(detector.detect).to eq(:apache)
      end
    end
  end

  describe '#system_dependencies' do
    it 'returns nginx for nginx' do
      allow(detector).to receive(:detect).and_return(:nginx)
      expect(detector.system_dependencies).to eq(['nginx'])
    end

    it 'returns apache2 for apache' do
      allow(detector).to receive(:detect).and_return(:apache)
      expect(detector.system_dependencies).to eq(['apache2'])
    end

    it 'returns empty for standalone' do
      allow(detector).to receive(:detect).and_return(:standalone)
      expect(detector.system_dependencies).to be_empty
    end
  end

  describe '#port' do
    it 'returns 3000 for standalone' do
      allow(detector).to receive(:detect).and_return(:standalone)
      expect(detector.port).to eq(3000)
    end

    it 'returns 80 for other servers' do
      allow(detector).to receive(:detect).and_return(:nginx)
      expect(detector.port).to eq(80)

      allow(detector).to receive(:detect).and_return(:apache)
      expect(detector.port).to eq(80)
    end
  end
end