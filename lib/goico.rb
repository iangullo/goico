require "rainbow"
require "thor"
require "git"
require_relative "goico/version"
require_relative "goico/i18n"
require_relative "goico/train"  # Changed from tren

module Goico
  class Error < StandardError; end

  # Initialize I18n when module loads
  I18n.setup
  I18n.set_locale

  def self.travel(app_path = ".", options = {})
    Train.new(app_path, options).travel  # Primary English method
  end

  # Spanish alias for backward compatibility
  def self.viajar(app_path = ".", options = {})
    travel(app_path, options)
  end

  # Helper method for translations
  def self.t(key, **options)
    I18n.t(key, **options)
  end

  # Method to change locale at runtime
  def self.set_locale(locale)
    I18n.set_locale(locale)
  end
end