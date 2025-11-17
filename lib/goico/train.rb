module Goico
  class Train
    def initialize(app_path, options = {})
      @app_path = File.expand_path(app_path)
      @options = options
      @config = {}
    end

    def travel
      say("goico.starting")

      detect_stations
      generate_configurations

      packager = choose_packager
      result = packager.build

      say("goico.success", :green)
      say("goico.package_created", :cyan, path: result[:package_path])

      result
    end

    private

    def detect_stations
      say("goico.detecting_features", :blue)

      @config.merge!({
        app_name: detect_app_name,
        database: Detectors::Database.new(@app_path).detect,
        javascript: Detectors::Javascript.new(@app_path).detect,
        dependencies: Detectors::Dependencies.new(@app_path).detect,
        infrastructure: Detectors::Infrastructure.new(@app_path).detect
      })

      say("goico.app_name", :blue, name: @config[:app_name])
      say("goico.database", :blue, type: @config[:database])
      say("goico.javascript", :blue, framework: @config[:javascript])
      say("goico.webserver", :blue, server: @config[:infrastructure][:webserver])
    end

    def generate_configurations
      # Generate init system configuration
      generate_init_system

      # Generate webserver configuration
      generate_webserver_config

      # Generate SSL configuration if requested
      generate_ssl_config

      # Generate Puma configuration if using standalone
      if @config[:infrastructure][:webserver] == :standalone
        Generators::Puma.new(@app_path, @config, @options).generate
      end

      # Generate database configuration
      Generators::Database.new(@app_path, @config, @options).generate
    end

    def choose_packager
      packager_type = @options[:type] || "deb"

      case packager_type
      when "deb" then Packagers::Deb.new(@app_path, @config, @options)
      when "rpm" then Packagers::Rpm.new(@app_path, @config, @options)
      when "brew" then Packagers::Brew.new(@app_path, @config, @options)
      when "tar" then Packagers::Tar.new(@app_path, @config, @options)
      else
        error_message = Goico.t("goico.errors.unknown_packager", type: packager_type)
        raise Error, error_message
      end
    end

    def generate_init_system
      case @options[:init_system]
      when "systemd"
        Generators::Systemd.new(@app_path, @config, @options).generate
      when "initv"
        Generators::Initv.new(@app_path, @config, @options).generate
      when "launchd"
        Generators::Launchd.new(@app_path, @config, @options).generate
      else
        # Auto-detect
        if RUBY_PLATFORM =~ /darwin/
          Generators::Launchd.new(@app_path, @config, @options).generate
        else
          File.exist?('/run/systemd/system') ?
            Generators::Systemd.new(@app_path, @config, @options).generate :
            Generators::Initv.new(@app_path, @config, @options).generate
        end
      end
    end

    def generate_webserver_config
      # Use SSL config if SSL is enabled and domain is provided
      if @options[:ssl] && @options[:domain]
        Generators::Webserver.new(@app_path, @config, @options.merge(ssl: true)).generate
      else
        Generators::Webserver.new(@app_path, @config, @options).generate
      end
    end

    def generate_ssl_config
      return unless @options[:ssl]

      if @options[:domain]
        Generators::Ssl.new(@app_path, @config, @options).generate
      else
        say("goico.ssl_missing_domain", :yellow)
      end
    end

    def detect_app_name
      if File.exist?(File.join(@app_path, "config", "application.rb"))
        content = File.read(File.join(@app_path, "config", "application.rb"))
        if match = content.match(/module\s+(\w+)/)
          return match[1].underscore
        end
      end

      File.basename(@app_path)
    end

    def say(message_key, color = :default, **options)
      message = Goico.t(message_key, **options)
      puts Rainbow(message).color(color)
    end
  end
end