# lib/goico/packager/base.rb
#
# Base class for packaging Rails apps with Goico
# Responsibilities:
#  - Manage staging directory
#  - Pull app metadata from manifest
#  - Generate postinstall script
#  - Resolve dependencies via SystemPackages
#  - Provide helper methods for FPM, Brew, and Tar builders
#
require_relative "base"
require "fpm/package"

module Goico
  module Packager
    class FPM < Base
      def build(target)
        prepare_dependencies
        clean_staging

        pkg_type = target.to_sym
        FPM::Package.build(
          source: staging_dir,
          target: pkg_type,
          name: app_name,
          version: app_version,
          after_install: write_postinstall_script,
          depends: dependencies.join(",")
        )
      end

      private

      def write_postinstall_script
        path = File.join(staging_dir, "postinstall.sh")
        File.write(path, postinstall_script)
        FileUtils.chmod(0o755, path)
        path
      end
    end
  end
end
