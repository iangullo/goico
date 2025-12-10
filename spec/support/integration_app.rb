# spec/support/integration_app.rb
require "fileutils"

module IntegrationApp
  def build_test_app!(root)
    FileUtils.mkdir_p("#{root}/config")
    File.write("#{root}/config/application.rb", "module TestApp; class Application; end; end")

    File.write("#{root}/Gemfile", <<~GEMFILE)
      source "https://rubygems.org"
      gem "rails"
      gem "pg"
      gem "puma"
      gem "sidekiq"
      gem "ruby-vips"
    GEMFILE

    FileUtils.mkdir_p("#{root}/app")
    FileUtils.mkdir_p("#{root}/bin")
    File.write("#{root}/bin/rails", "#!/usr/bin/env ruby\nputs 'rails'")
    FileUtils.chmod("+x", "#{root}/bin/rails")
  end
end
