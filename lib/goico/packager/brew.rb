# lib/goico/packager/brew.rb
require "erb"

module Goico
  module Packager
    class Brew < Base
      private

      def package(_target)
        formula_path = File.join(staging_dir, "#{manifest['capabilities']['app_name']}.rb")
        template = File.read(File.join(__dir__, "templates", "brew.rb.erb"))
        renderer = ERB.new(template)
        File.write(formula_path, renderer.result(binding))
        puts "Homebrew formula generated: #{formula_path}"
      end
    end
  end
end
