require 'spec_helper'

RSpec.describe Goico::I18n do
  describe '.setup' do
    it 'loads all locale files' do
      expect(Goico::I18n.available_locales).to contain_exactly(:en, :es, :fr)
    end

    it 'sets default locale to English' do
      expect(Goico::I18n.current_locale).to eq(:en)
    end
  end

  describe '.detect_locale' do
    before { Goico::I18n.setup }

    it 'detects locale from environment variables' do
      ClimateControl.modify LANG: 'es_ES.UTF-8' do
        expect(Goico::I18n.detect_locale).to eq(:es)
      end
    end

    it 'falls back to English for unknown locales' do
      ClimateControl.modify LANG: 'de_DE.UTF-8' do
        expect(Goico::I18n.detect_locale).to eq(:en)
      end
    end

    it 'prefers CLI arguments over environment' do
      original_argv = ARGV.dup
      ARGV.replace(['--locale', 'fr'])

      expect(Goico::I18n.detect_locale).to eq(:fr)

      ARGV.replace(original_argv)
    end
  end

  describe '.set_locale' do
    it 'changes the current locale' do
      Goico::I18n.set_locale(:fr)
      expect(Goico::I18n.current_locale).to eq(:fr)
    end

    it 'handles string locales' do
      Goico::I18n.set_locale('es')
      expect(Goico::I18n.current_locale).to eq(:es)
    end
  end

  describe '.t' do
    it 'translates existing keys' do
      expect(Goico::I18n.t('cli.banner')).to be_a(String)
      expect(Goico::I18n.t('goico.starting')).to be_a(String)
    end

    it 'handles variables in translations' do
      result = Goico::I18n.t('cli.success', path: '/test.pkg')
      expect(result).to include('/test.pkg')
    end
  end

  describe '.exists?' do
    it 'returns true for existing keys' do
      expect(Goico::I18n.exists?('cli.banner')).to be true
    end

    it 'returns false for non-existent keys' do
      expect(Goico::I18n.exists?('nonexistent.key')).to be false
    end
  end
end