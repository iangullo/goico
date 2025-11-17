module Goico
  module Packagers
    class Base
      def initialize(app_path, config, options)
        @app_path = app_path
        @config = config
        @options = options
        @build_dir = File.join(Dir.tmpdir, "goico-build-#{Time.now.to_i}")
      end

      def build
        prepare_directories
        copy_application
        generate_configurations
        build_package
      ensure
        clean_directories
      end

      protected

      def prepare_directories
        FileUtils.mkdir_p(@build_dir)
      end

      def copy_application
        raise NotImplementedError, "Subclasses must implement copy_application"
      end

      def generate_configurations
        raise NotImplementedError, "Subclasses must implement generate_configurations"
      end

      def build_package
        raise NotImplementedError, "Subclasses must implement build_package"
      end

      def clean_directories
        FileUtils.rm_rf(@build_dir) if File.exist?(@build_dir)
      end

      def say(message_key, color = :default, **options)
        message = Goico.t(message_key, **options)
        puts Rainbow(message).color(color)
      end

      def setup_application
        install_gems
        setup_javascript
        precompile_assets
        setup_database
      end

      def install_gems
        say("goico.installing_gems")
        bundle_command = "bundle config set without 'development test' && bundle install --deployment --jobs $(nproc)"
        run_in_app(bundle_command)
      end

      def setup_javascript
        case @config[:javascript]
        when :importmap
          setup_importmap_js
        when :node, :webpack
          setup_node_js
        end
      end

      def setup_importmap_js
        say("goico.setup_importmap")
        # Importmap doesn't need npm install, but we should ensure pins are correct
        run_in_app("./bin/importmap pin --all") if File.exist?(File.join(app_build_path, "bin/importmap"))
      end

      def setup_node_js
        say("goico.setup_nodejs")
        if File.exist?(File.join(app_build_path, "package.json"))
          run_in_app("npm install")
          run_in_app("npm run build") if package_json_has_build_script?
        end
      end

      def precompile_assets
        say("goico.precompiling_assets")
        run_in_app("RAILS_ENV=production bundle exec rails assets:precompile")
      end

      def setup_database
        say("goico.setup_database")
        # ... rest of method
      end

      def run_in_app(command)
        Dir.chdir(app_build_path) { system(command) }
      end

      def app_build_path
        @build_dir # Override in subclasses if app is in subdirectory
      end

      def package_json_has_build_script?
        package_json_path = File.join(app_build_path, "package.json")
        return false unless File.exist?(package_json_path)

        package_json = JSON.parse(File.read(package_json_path))
        package_json["scripts"] && package_json["scripts"]["build"]
      end

      def importmap_needs_pin?(package)
        importmap_path = File.join(app_build_path, "config/importmap.rb")
        return false unless File.exist?(importmap_path)

        importmap_content = File.read(importmap_path)
        !importmap_content.include?(package)
      end

      def app_name
        @config[:app_name]
      end
    end
  end
end