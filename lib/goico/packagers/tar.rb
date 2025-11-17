require_relative 'base'
require 'zlib'
require 'archive/tar/minitar'

module Goico
  module Packagers
    class Tar < Base
      def build_package
        say("goico.building_tar_package")

        tar_path = "#{@build_dir}/#{app_name}-#{@options[:version] || '1.0.0'}.tar"

        # Create tarball
        File.open(tar_path, 'wb') do |tar_file|
          Zlib::GzipWriter.wrap(tar_file) do |gzip|
            Archive::Tar::Minitar::Writer.open(gzip) do |writer|
              add_directory_to_tar(writer, @build_dir, "")
            end
          end
        end

        # Move to final location
        final_path = "#{Dir.pwd}/#{File.basename(tar_path)}.gz"
        FileUtils.mv("#{tar_path}.gz", final_path)

        say("goico.built_tar_package", :green, path: final_path)

        { package_path: final_path, format: :tar }
      end

      def copy_application
        say("goico.copying_application_files")

        # Copy application
        FileUtils.mkdir_p("#{@build_dir}/app")
        FileUtils.cp_r("#{@app_path}/.", "#{@build_dir}/app/")

        # Generate deployment scripts
        generate_deployment_scripts
      end

      def generate_configurations
        # Generate configuration files for tar deployment
        generate_puma_config
        generate_database_config
        generate_env_file
      end

      private

      def add_directory_to_tar(writer, base_path, tar_path)
        Dir.foreach(base_path) do |entry|
          next if entry == '.' || entry == '..'

          full_path = File.join(base_path, entry)
          tar_entry_path = File.join(tar_path, entry)

          if File.directory?(full_path)
            writer.mkdir(tar_entry_path, File.stat(full_path).mode)
            add_directory_to_tar(writer, full_path, tar_entry_path)
          else
            writer.add_file(tar_entry_path, File.stat(full_path).mode) do |io|
              io.write(File.read(full_path))
            end
          end
        end
      end

      def generate_deployment_scripts
        deploy_script = <<~SCRIPT
        #!/bin/bash
        # Deployment script for #{app_name}
        echo "Deploying #{app_name}..."

        # Extract and setup
        tar xzf #{app_name}-*.tar.gz
        cd #{app_name}-*

        # Install dependencies
        bundle install --deployment

        # Setup database
        bundle exec rails db:create db:migrate

        # Precompile assets
        bundle exec rails assets:precompile

        echo "Deployment complete!"
        SCRIPT

        File.write("#{@build_dir}/deploy.sh", deploy_script)
        FileUtils.chmod(0755, "#{@build_dir}/deploy.sh")
      end

      def generate_env_file
        env_content = <<~ENV
        RAILS_ENV=production
        DATABASE_URL=postgresql://localhost/#{app_name}_production
        SECRET_KEY_BASE=please-change-me-in-production
        ENV

        File.write("#{@build_dir}/.env", env_content)
      end
    end
  end
end