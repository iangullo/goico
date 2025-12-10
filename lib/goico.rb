# lib/goico.rb
# Goico main entry point

require_relative "goico/version"
require_relative "core/i18n"

module Goico
  class << self
    # Entry point for CLI invocation
    # Lazily loads CLI and executes it
    def start(argv = ARGV)
      require_relative "goico/cli"
      CLI.new(argv).run
    end

    # -----------------------------
    # Lazy accessors for components
    # -----------------------------
    def analyzer
      require_relative "goico/analyzer/base"
      require_relative "goico/analyzer/app_server"
      require_relative "goico/analyzer/database"
      require_relative "goico/analyzer/gems"
      Analyzer
    end

    def installer
      require_relative "goico/installer/base"
      require_relative "goico/installer/base_service_generator"
      require_relative "goico/installer/platform"
      require_relative "goico/installer/postinstall_generator"
      require_relative "goico/installer/service_generator"
      require_relative "goico/installer/worker_service_generator"
      require_relative "goico/installer/webserver_generator"
      require_relative "goico/installer/system_packages"
      Installer
    end

    def packager
      require_relative "goico/packager/base"
      require_relative "goico/packager/fpm"
      require_relative "goico/packager/brew"
      require_relative "goico/packager/tar"
      Packager
    end

    def manifest_validator
      require_relative "goico/manifest/validator"
      Manifest::Validator
    end
  end
end
