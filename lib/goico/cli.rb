# lib/goico/cli.rb
# CLI entry point for Goico
require "optparse"
require "ostruct"

module Goico
  class CLI
    attr_reader :argv, :options

    def initialize(argv = ARGV)
      @argv = argv
      @options = OpenStruct.new
    end

    def run
      parse_options
      validate_options
      execute_task
    end

    private

    def parse_options
      parser = OptionParser.new do |opts|
        opts.banner = Goico::Core::I18n.t("cli.banner")

        opts.on("-t", "--type TYPE", String, Goico::Core::I18n.t("cli.options.type.description")) do |v|
          options.type = v.downcase.to_sym
        end

        opts.on("--app-name NAME", String, Goico::Core::I18n.t("cli.options.app_name.description")) do |v|
          options.app_name = v
        end

        opts.on("-w", "--webserver SERVER", String, Goico::Core::I18n.t("cli.options.webserver.description")) do |v|
          options.webserver = v.downcase.to_sym
        end

        opts.on("--init-system SYSTEM", String, Goico::Core::I18n.t("cli.options.init_system.description")) do |v|
          options.init_system = v.downcase.to_sym
        end

        opts.on("--domain DOMAIN", String, Goico::Core::I18n.t("cli.options.domain.description")) do |v|
          options.domain = v
        end

        opts.on("--ssl", Goico::Core::I18n.t("cli.options.ssl.description")) do
          options.ssl = true
        end

        opts.on("--rbenv", Goico::Core::I18n.t("cli.options.rbenv.description")) do
          options.rbenv = true
        end

        opts.on("-l", "--locale LOCALE", String, Goico::Core::I18n.t("cli.options.locale.description")) do |v|
          options.locale = v.to_sym
        end

        opts.on("-v", "--version", Goico::Core::I18n.t("cli.options.version_flag.description")) do
          puts Goico::Core::I18n.t("cli.version", version: Goico::VERSION)
          exit
        end

        opts.on("-h", "--help", Goico::Core::I18n.t("cli.options.help.description")) do
          puts opts
          exit
        end
      end

      parser.parse!(argv)

      # Positional argument: app path
      options.app_path = argv.shift
    end

    def validate_options
      unless options.app_path && File.directory?(options.app_path)
        raise Goico::Manifest::ValidationError,
              Goico::Core::I18n.t("errors.missing_app", path: options.app_path || "<none>")
      end

      valid_types = %i[deb rpm brew tar]
      if options.type && !valid_types.include?(options.type)
        raise Goico::Manifest::ValidationError,
              Goico::Core::I18n.t("errors.invalid_package_type", type: options.type, valid: valid_types.join(", "))
      end

      valid_webservers = %i[nginx apache standalone]
      if options.webserver && !valid_webservers.include?(options.webserver)
        raise Goico::Manifest::ValidationError,
              Goico::Core::I18n.t("errors.invalid_webserver", server: options.webserver, valid: valid_webservers.join(", "))
      end

      valid_inits = %i[systemd initd launchd]
      if options.init_system && !valid_inits.include?(options.init_system)
        raise Goico::Manifest::ValidationError,
              Goico::Core::I18n.t("errors.invalid_init_system", system: options.init_system, valid: valid_inits.join(", "))
      end
    end

    def execute_task
      puts Goico::Core::I18n.t("goico.starting")

      # Lazy-load manifest generator / analyzer
      manifest = generate_manifest

      # Lazy-load installer
      if %i[deb rpm brew tar].include?(options.type)
        Goico.installer.generate(manifest: manifest, options: options)
      end

      puts Goico::Core::I18n.t("goico.success")
    end

    def generate_manifest
      require_relative "analyzer/base"
      require_relative "manifest/validator"

      # Example: detect features automatically
      detected_manifest = Goico.analyzer::Base.detect_features(options.app_path, options)

      # Validate manifest
      Goico.manifest_validator.validate!(detected_manifest)
      detected_manifest
    end
  end
end
