# lib/goico/core/i18n.rb
require "i18n"
require "yaml"

module Goico
  module Core
    module I18nHelper
      LOCALES_PATH = File.expand_path("../../../locales/*.yml", __dir__)

      def self.setup!(locale: :en)
        I18n.load_path += Dir[LOCALES_PATH]
        I18n.available_locales = %i[en es fr pt]
        I18n.default_locale = :en
        I18n.locale = locale.to_sym
      end

      def self.t(key, **vars)
        I18n.t(key, **vars)
      rescue I18n::MissingTranslationData
        "⛔ Missing translation: #{key}"
      end
    end
  end
end
