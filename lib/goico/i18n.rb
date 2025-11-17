module Goico
  module I18n
    LOCALE_PATH = File.expand_path('../../../locales', __dir__)

    def self.setup
      require 'i18n'
      require 'i18n/backend/fallbacks'

      ::I18n::Backend::Simple.send(:include, ::I18n::Backend::Fallbacks)

      ::I18n.load_path += Dir[File.join(LOCALE_PATH, '*.yml')]
      ::I18n.enforce_available_locales = false
      ::I18n.default_locale = :en
      ::I18n.fallbacks = [:en]
    end

    def self.detect_locale
      # Check CLI arguments first
      if (idx = ARGV.index('--locale') || ARGV.index('-l'))
        locale = ARGV[idx + 1]&.to_sym
        return locale if available_locales.include?(locale)
      end

      # Check environment variables in order of preference
      locale = ENV['LANG']&.split('_')&.first&.to_sym ||
               ENV['LANGUAGE']&.split(':')&.first&.to_sym ||
               ENV['LC_ALL']&.split('_')&.first&.to_sym ||
               :en

      # Validate the locale is available
      available_locales.include?(locale) ? locale : :en
    end

    def self.set_locale(locale = nil)
      ::I18n.locale = locale || detect_locale
    end

    def self.current_locale
      ::I18n.locale
    end

    def self.available_locales
      ::I18n.config.available_locales
    end

    def self.t(key, **options)
      ::I18n.t(key, **options)
    end

    # Check if a translation exists
    def self.exists?(key)
      ::I18n.exists?(key)
    end
  end
end