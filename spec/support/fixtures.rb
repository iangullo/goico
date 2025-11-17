module TestFixtures
  def self.rails_app_with_nginx
    {
      'config/application.rb' => <<~RUBY,
        module NginxApp
          class Application < Rails::Application
          end
        end
      RUBY
      'config/database.yml' => <<~YAML,
        production:
          adapter: postgresql
          database: nginxapp_production
      YAML
      'Gemfile' => <<~RUBY,
        source 'https://rubygems.org'
        gem 'rails'
        gem 'pg'
        gem 'puma'
      RUBY
      'config/nginx.conf' => '# nginx config'
    }
  end

  def self.rails_app_with_mysql
    {
      'config/application.rb' => <<~RUBY,
        module MySQLApp
          class Application < Rails::Application
          end
        end
      RUBY
      'config/database.yml' => <<~YAML,
        production:
          adapter: mysql2
          database: mysqlapp_production
      YAML
      'Gemfile' => <<~RUBY,
        source 'https://rubygems.org'
        gem 'rails'
        gem 'mysql2'
        gem 'puma'
      RUBY
      'package.json' => <<~JSON,
        {
          "name": "mysqlapp",
          "scripts": {
            "build": "webpack"
          }
        }
      JSON
      'webpack.config.js' => '// webpack config'
    }
  end

  def self.rails_app_with_importmap
    {
      'config/application.rb' => <<~RUBY,
        module ImportmapApp
          class Application < Rails::Application
          end
        end
      RUBY
      'config/database.yml' => <<~YAML,
        production:
          adapter: sqlite3
          database: db/production.sqlite3
      YAML
      'Gemfile' => <<~RUBY,
        source 'https://rubygems.org'
        gem 'rails'
        gem 'sqlite3'
        gem 'importmap-rails'
      RUBY
      'config/importmap.rb' => <<~RUBY,
        Rails.application.importmap.draw do
          pin "application"
          pin "@hotwired/turbo-rails", to: "turbo.min.js"
        end
      RUBY
      'package.json' => nil # No package.json for importmap
    }
  end
end

RSpec.configure do |config|
  config.include TestFixtures
end