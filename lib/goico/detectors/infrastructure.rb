# lib/goico/detectors/infrastructure.rb
module Goico
  module Detectors
    class Infrastructure < Base
      def detect
        {
          webserver: webserver_detector.detect,
          background_processor: detect_background_processor,
          cache_store: detect_cache_store,
          ruby_manager: detect_ruby_manager,
          app_server: detect_app_server
        }
      end

      def system_dependencies
        deps = []
        infra = detect

        # Webserver dependencies
        deps += webserver_detector.system_dependencies

        # Cache store dependencies
        deps << "redis-server" if infra[:cache_store] == :redis
        deps << "memcached" if infra[:cache_store] == :memcached

        # Background processor dependencies
        deps << "redis-server" if infra[:background_processor] == :sidekiq

        # Ruby manager
        deps += case infra[:ruby_manager]
                when :rbenv then ['rbenv', 'ruby-build']
                when :rvm then ['rvm']
                when :chruby then ['chruby']
                else [] # System ruby
                end

        deps.uniq
      end

      private

      def webserver_detector
        @webserver_detector ||= Webserver.new(@app_path, @options)
      end

      def detect_background_processor
        return :none unless has_gemfile?

        content = cached_gemfile_content
        case
        when content.include?("sidekiq") then :sidekiq
        when content.include?("good_job") then :good_job
        when content.include?("delayed_job") then :delayed_job
        when content.include?("resque") then :resque
        when content.include?("sneakers") then :sneakers
        when content.match?(/gem ['"]shoryuken['"]/) then :shoryuken
        else :none
        end
      end

      def detect_cache_store
        return :file unless has_gemfile?

        content = cached_gemfile_content
        case
        when content.include?("redis") then :redis
        when content.include?("dalli") then :memcached
        when content.include?("memcached") then :memcached
        else :file
        end
      end

      def detect_ruby_manager
        # Check for version manager files
        return :rbenv if cached_file_exists?(File.join(@app_path, '.ruby-version'))
        return :rvm if cached_file_exists?(File.join(@app_path, '.rvmrc')) ||
                       (cached_file_exists?(File.join(@app_path, '.ruby-version')) &&
                        cached_file_content(File.join(@app_path, '.ruby-version')).include?('@'))
        return :chruby if cached_file_exists?(File.join(@app_path, '.ruby-version'))

        # Check Gemfile for ruby version constraint
        if has_gemfile? && cached_gemfile_content.include?('ruby ')
          :rbenv # Default to rbenv if Ruby version is specified
        else
          :system # Use system Ruby
        end
      end

      def detect_app_server
        return :puma if cached_file_exists?(File.join(@app_path, 'config/puma.rb'))
        return :unicorn if cached_file_exists?(File.join(@app_path, 'config/unicorn.rb'))
        return :passenger if has_gemfile? && cached_gemfile_content.include?('passenger')

        :puma # Rails default
      end
    end
  end
end