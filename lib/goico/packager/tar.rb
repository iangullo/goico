# lib/goico/packager/tar.rb
require_relative "base"
require "fileutils"

module Goico
  module Packager
    class Tar < Base
      def build
        prepare_dependencies
        clean_staging

        # Copy app files
        FileUtils.cp_r("#{manifest['app_path']}/.", staging_dir)

        tar_path = "#{app_name}-#{app_version}.tar.gz"
        system("tar -czf #{tar_path} -C #{staging_dir} .")
        puts "Tarball created at #{tar_path}"
      end
    end
  end
end
