require "thor"
require "yaml"

require_relative "../analyzer/base"
require_relative "../packager/base"
require_relative "../core/i18n"

module Goico
  class CLI < Thor
    desc "analyze PATH", Goico::Core::I18nHelper.t("cli.commands.analyze")
    option :out, aliases: "-o", default: "goico-manifest.yml", desc: Goico::Core::I18nHelper.t("cli.options.out.description")
    def analyze(path = ".")
      puts Goico::Core::I18nHelper.t("goico.detecting_features")

      analyzer = Goico::Analyzer::Base.new(path)
      manifest = analyzer.analyze

      File.write(options[:out], manifest.to_yaml)

      puts Goico::Core::I18nHelper.t("cli.manifest_written", path: options[:out])
    rescue Interrupt
      puts Goico::Core::I18nHelper.t("cli.interrupted")
    rescue => e
      puts Goico::Core::I18nHelper.t("cli.error", message: e.message)
    end


    desc "generate PATH", Goico::Core::I18nHelper.t("cli.commands.generate")
    option :targets, type: :array, default: ["deb", "tar"], desc: Goico::Core::I18nHelper.t("cli.options.targets.description")
    def generate(path = ".")
      invoke :analyze, [path]

      manifest = YAML.load_file("goico-manifest.yml")

      builder = Goico::Packager::Base.new(manifest)
      options[:targets].each do |target|
        builder.build(target)
      end

      puts Goico::Core::I18nHelper.t("goico.success")
    rescue => e
      puts Goico::Core::I18nHelper.t("cli.unexpected_error")
      puts Goico::Core::I18nHelper.t("cli.error", message: e.message)
    end


    desc "version", Goico::Core::I18nHelper.t("cli.commands.version")
    def version
      puts Goico::Core::I18nHelper.t("goico.version", version: Goico::VERSION)
    end
  end
end
