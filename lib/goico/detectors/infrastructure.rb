module Goico
  module Detectors
    class Infrastructure
      def initialize(app_path)
        @app_path = app_path
      end

      def detect
        {
          webserver: Webserver.new(@app_path).detect,
          background_processor: detect_background_processor,
          cache_store: detect_cache_store,
          ruby_manager: detect_ruby_manager
        }
      end

      def system_dependencies
        deps = []
        infra = detect

        # Webserver dependencies
        deps += Webserver.new(@app_path).system_dependencies

        # Cache store dependencies
        deps << "redis-server" if infra[:cache_store] == :redis
        deps << "memcached" if infra[:cache_store] == :memcached

        # Ruby manager
        deps += case infra[:ruby_manager]
                when :rbenv then ['rbenv', 'ruby-build']
                when :rvm then ['rvm']
                else [] # System ruby
                end

        deps.uniq
      end

      private

      def detect_background_processor
        gemfile_path = File.join(@app_path, "Gemfile")
        if File.exist?(gemfile_path)
          content = File.read(gemfile_path)
          return :sidekiq if content.include?("sidekiq")
          return :good_job if content.include?("good_job")
          return :delayed_job if content.include?("delayed_job")
          return :resque if content.include?("resque")
        end
        :none
      end

      def detect_cache_store
        gemfile_path = File.join(@app_path, "Gemfile")
        if File.exist?(gemfile_path)
          content = File.read(gemfile_path)
          return :redis if content.include?("redis")
          return :memcached if content.include?("dalli")
        end
        :file
      end

      def detect_ruby_manager
        # Check for rbenv or rvm files
        return :rbenv if File.exist?(File.join(@app_path, '.ruby-version'))
        return :rvm if File.exist?(File.join(@app_path, '.rvmrc'))

        # Default to rbenv for better isolation
        :rbenv
      end
    end
  end
end