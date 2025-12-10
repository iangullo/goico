# lib/goico/packager/brew.rb
require_relative "base"

module Goico
  module Packager
    class Brew < Base
      def build
        prepare_dependencies
        clean_staging
        formula_path = File.join(staging_dir, "#{app_name}.rb")

        template = File.read(File.expand_path("templates/brew.rb.erb", __dir__))
        content  = ERB.new(template).result(binding)

        File.write(formula_path, content)
        puts "Brew formula generated at #{formula_path}"
      end
    end
  end
end
