# lib/goico/packager/tar.rb
module Goico
  module Packager
    class Tar < Base
      private

      def package(_target)
        tarball = "#{manifest['capabilities']['app_name'] || 'rails_app'}-#{manifest['capabilities']['version'] || '0.1.0'}.tar.gz"
        Dir.chdir(staging_dir) do
          system("tar czf #{tarball} .")
        end
        puts "TAR package created: #{File.join(staging_dir, tarball)}"
      end
    end
  end
end
