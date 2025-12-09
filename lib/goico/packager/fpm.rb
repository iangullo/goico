# lib/goico/packager/fpm/base.rb
rerequire "fpm/package"

module Goico
  module Packager
    module FPM
      class Base < Packager::Base
        def package(target)
          case target.to_sym
          when :deb then build_deb
          when :rpm then build_rpm
          else
            raise "Unsupported FPM target: #{target}"
          end
        end

        private

        def build_deb
          FPM::Package.build(
            source: staging_dir,
            target: "deb",
            name: manifest['capabilities']['app_name'],
            version: manifest['capabilities']['version'],
            after_install: postinstall_script_path,
            depends: @dependencies.join(",")
          )
        end

        def build_rpm
          FPM::Package.build(
            source: staging_dir,
            target: "rpm",
            name: manifest['capabilities']['app_name'],
            version: manifest['capabilities']['version'],
            after_install: postinstall_script_path,
            depends: @dependencies.join(",")
          )
        end

        def postinstall_script_path
          File.join(staging_dir, "postinstall.sh")
        end
      end
    end
  end
end
