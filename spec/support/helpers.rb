module TestHelpers
  def create_temp_rails_app(structure = {})
    dir = Dir.mktmpdir('goico-test-app-', $test_tmp_dir)

    # Default Rails-like structure
    default_structure = {
      'config/application.rb' => <<~RUBY,
        module TestApp
          class Application < Rails::Application
            config.load_defaults 8.0
          end
        end
      RUBY
      'config/database.yml' => <<~YAML,
        production:
          adapter: postgresql
          database: testapp_production
          username: testapp
      YAML
      'Gemfile' => <<~RUBY,
        source 'https://rubygems.org'
        gem 'rails', '~> 8.0.0'
        gem 'pg'
        gem 'puma'
      RUBY
      'config/puma.rb' => '# Puma config',
      'package.json' => '{"name": "testapp"}',
      'config/importmap.rb' => 'Rails.application.importmap.draw {}'
    }

    # Merge with custom structure
    structure = default_structure.merge(structure)

    # Create files
    structure.each do |path, content|
      full_path = File.join(dir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content) if content
    end

    dir
  end

  def create_minimal_rails_app
    create_temp_rails_app({
      'config/application.rb' => <<~RUBY,
        module MinimalApp
          class Application < Rails::Application
          end
        end
      RUBY
      'config/database.yml' => nil, # No database config
      'Gemfile' => "gem 'rails'",
      'config/puma.rb' => nil,
      'package.json' => nil,
      'config/importmap.rb' => nil
    })
  end

  def with_temp_app(structure = {})
    app_path = create_temp_rails_app(structure)
    yield app_path
  ensure
    FileUtils.remove_entry(app_path) if app_path && File.exist?(app_path)
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end