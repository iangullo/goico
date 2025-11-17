require_relative 'base'

module Goico
  module Generators
    class Puma < Base
      def generate
        say("goico.generating_puma")

        template_path = File.join('common', 'puma', 'config.erb')
        output_path = File.join(@app_path, 'config', 'puma.rb')

        # Only generate if it doesn't exist
        unless File.exist?(output_path)
          template(template_path, output_path,
                   context: binding,
                   app_name: app_name)
          say("goico.generated_puma", :green, path: output_path)
        else
          say("goico.skipping_puma", :yellow)
        end
      end
    end
  end
end