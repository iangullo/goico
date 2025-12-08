# lib/goico/generators/scripts.rb
require_relative 'base'

module Goico
  module Generators
    class Scripts < Base
      def generate
        say("goico.generating_scripts")

        generate_pre_install_script
        generate_post_install_script
        generate_asset_compilation_script
        generate_maintenance_scripts

        say("goico.generated_scripts", :green)
      end

      private

      def generate_pre_install_script
        template_path = File.join('scripts', 'preinstall.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'preinstall.sh')

        template(template_path, output_path, locals: pre_install_locals)
        set_secure_permissions(output_path, :root_only)
      end

      def generate_post_install_script
        template_path = File.join('scripts', 'postinstall.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'postinstall.sh')

        template(template_path, output_path, locals: post_install_locals)
        set_secure_permissions(output_path, :root_only)
      end

      def generate_asset_compilation_script
        return unless needs_asset_compilation?

        template_path = File.join('scripts', 'asset_precompile.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'assets.sh')

        template(template_path, output_path, locals: asset_compilation_locals)
        set_secure_permissions(output_path, :app_user_only)
      end

      def generate_maintenance_scripts
        generate_database_migration_script  # App user only
        generate_cleanup_script             # App user only
        generate_backup_script              # Mixed - might need root for some ops
      end

      def generate_database_migration_script
        template_path = File.join('scripts', 'migrate.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'migrate.sh')

        template(template_path, output_path, locals: migration_locals)
        set_secure_permissions(output_path, :app_user_only)
      end

      def generate_cleanup_script
        template_path = File.join('scripts', 'cleanup.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'cleanup.sh')

        template(template_path, output_path, locals: cleanup_locals)
        set_secure_permissions(output_path, :app_user_only)
      end

      def generate_backup_script
        template_path = File.join('scripts', 'backup.erb')
        output_path = File.join(@app_path, 'config', 'deploy', 'backup.sh')

        template(template_path, output_path, locals: backup_locals)
        set_secure_permissions(output_path, :app_user_only)
      end

      def set_secure_permissions(file_path, permission_type)
        case permission_type
        when :root_only
          # 0700 - Only owner (root) can read/write/execute
          FileUtils.chmod(0700, file_path)
        when :app_user_only
          # 0750 - Owner read/write/execute, group read/execute, others nothing
          FileUtils.chmod(0750, file_path)
        when :read_only
          # 0644 - Owner read/write, others read-only (for config files, not scripts)
          FileUtils.chmod(0644, file_path)
        else
          # Default secure: 0750
          FileUtils.chmod(0750, file_path)
        end
      end

      def needs_asset_compilation?
        # Check if this Rails app has assets that need compilation
        js_detector = Goico::Detectors::Javascript.new(@app_path)
        js_type = js_detector.detect

        js_type != :importmap ||
        File.exist?(File.join(@app_path, 'app/assets')) ||
        File.exist?(File.join(@app_path, 'config/assets.rb'))
      end

      def pre_install_locals
        {
          app_name: app_name,
          dependencies: all_system_dependencies,
          user: @options[:user] || app_name,
          group: @options[:group] || app_name,
          install_path: app_install_path,
          config_path: config_install_path,
          log_path: log_path,
          run_path: run_path
        }
      end

      def post_install_locals
        {
          app_name: app_name,
          database_type: @analysis[:database],
          needs_assets: needs_asset_compilation?,
          service_type: determine_service_type,
          ssl_enabled: should_configure_ssl?,
          domain: @options[:domain]
        }
      end

      def asset_compilation_locals
        js_detector = Goico::Detectors::Javascript.new(@app_path)
        {
          app_name: app_name,
          install_path: app_install_path,
          javascript_runtime: js_detector.detect,
          rails_env: 'production'
        }
      end

      def migration_locals
        {
          app_name: app_name,
          install_path: app_install_path,
          database_type: @analysis[:database],
          rails_env: 'production'
        }
      end

      def cleanup_locals
        {
          app_name: app_name,
          log_path: log_path,
          tmp_path: "#{app_install_path}/tmp",
          cache_path: "#{app_install_path}/tmp/cache"
        }
      end

      def backup_locals
        {
          app_name: app_name,
          database_type: @analysis[:database],
          backup_path: @options[:backup_path] || "/var/backups/#{app_name}",
          database_name: "#{app_name}_production"
        }
      end

      def all_system_dependencies
        # Aggregate dependencies from all detectors
        deps = []
        deps += Goico::Detectors::Dependencies.new(@app_path).system_dependencies
        deps += Goico::Detectors::Infrastructure.new(@app_path).system_dependencies
        deps.uniq
      end

      def determine_service_type
        # Logic to determine if it's systemd, launchd, etc.
        @analysis[:platform] == :macos ? :launchd : :systemd
      end
    end
  end
end