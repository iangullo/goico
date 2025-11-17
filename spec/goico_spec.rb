require 'spec_helper'

RSpec.describe Goico do
  describe '.travel' do
    it 'packages a Rails application' do
      with_temp_app do |app_path|
        expect { Goico.travel(app_path, type: 'tar') }.not_to raise_error
      end
    end

    it 'respects package type option' do
      with_temp_app do |app_path|
        result = Goico.travel(app_path, type: 'tar')
        expect(result[:format]).to eq(:tar)
      end
    end

    it 'handles minimal Rails applications' do
      app_path = create_minimal_rails_app
      expect { Goico.travel(app_path, type: 'tar') }.not_to raise_error
    ensure
      FileUtils.remove_entry(app_path) if app_path
    end
  end

  describe '.set_locale' do
    it 'changes the current locale' do
      Goico.set_locale(:es)
      expect(Goico::I18n.current_locale).to eq(:es)
    end

    it 'affects translations' do
      Goico.set_locale(:es)
      expect(Goico.t('cli.banner')).to include('Uso:')

      Goico.set_locale(:en)
      expect(Goico.t('cli.banner')).to include('Usage:')
    end
  end

  describe '.t' do
    it 'translates keys' do
      expect(Goico.t('cli.banner')).to be_a(String)
    end

    it 'handles variables in translations' do
      translation = Goico.t('cli.success', path: '/test.pkg')
      expect(translation).to include('/test.pkg')
    end

    it 'returns the key for missing translations' do
      expect(Goico.t('nonexistent.key')).to eq('nonexistent.key')
    end
  end

  describe 'Error class' do
    it 'is a standard error' do
      expect(Goico::Error.ancestors).to include(StandardError)
    end

    it 'can be raised with a message' do
      expect { raise Goico::Error, 'test error' }.to raise_error(Goico::Error, 'test error')
    end
  end
end