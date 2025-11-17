require_relative 'base'

module Goico
  module Packagers
    class Brew < Base
      def build_package
        say("goico.building_brew_formula")

        formula_content = generate_formula
        formula_path = "#{@build_dir}/#{formula_name}.rb"

        File.write(formula_path, formula_content)
        say("goico.built_brew_formula", :green, path: formula_path)

        { package_path: formula_path, format: :brew }
      end

      private

      def formula_name
        @options[:formula_name] || app_name
      end

      def generate_formula
        <<~RUBY
        class #{formula_name.camelize} < Formula
          desc "#{@options[:description] || "#{app_name.humanize} Rails Application"}"
          homepage "https://#{app_name}.com"
          url "https://github.com/#{@options[:repo] || "user/#{app_name}"}/archive/v#{@options[:version] || '1.0.0'}.tar.gz"
          sha256 "#{@options[:sha256] || 'TODO_CALCULATE_ACTUAL_SHA'}"

          depends_on "postgresql" if #{@config[:database] == :postgresql}
          depends_on "mysql" if #{@config[:database] == :mysql}
          depends_on "redis" if #{@config[:infrastructure][:cache_store] == :redis}
          depends_on "rbenv" if #{@config[:infrastructure][:ruby_manager] == :rbenv}
          #{webserver_dependencies}

          def install
            # Install application files
            libexec.install Dir["*"]

            # Create config directory
            (etc/"#{app_name}").mkpath

            # Create service script
            (bin/"#{app_name}-server").write start_script
          end

          def post_install
            # Setup database if needed
            system "cd \#{libexec} && bundle exec rails db:create db:migrate" if #{@config[:database] != :sqlite}
          end

          service do
            run [bin/"#{app_name}-server", "start"]
            working_dir libexec
            environment_variables RAILS_ENV: "production"
          end

          def start_script
            <<~EOS
            #!/bin/bash
            cd \#{libexec}
            bundle install --deployment
            bundle exec rails server -e production
            EOS
          end

          #{webserver_dependencies_method}
        end
        RUBY
      end

      def webserver_dependencies
        case @config[:infrastructure][:webserver]
        when :nginx then 'depends_on "nginx"'
        when :apache then 'depends_on "httpd"'
        else ''
        end
      end

      def webserver_dependencies_method
        case @config[:infrastructure][:webserver]
        when :nginx then 'def nginx_config; "nginx config content"; end'
        when :apache then 'def apache_config; "apache config content"; end'
        else ''
        end
      end
    end
  end
end