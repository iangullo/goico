require 'bundler/setup'
require 'goico'
require 'fileutils'
require 'tmpdir'
require 'rspec/collection_matchers'

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.formatter = :documentation
  config.color = true
  config.order = :random

  # Include helpers
  config.include TestHelpers

  # Set up test environment
  config.before(:suite) do
    # Create a temporary directory for test artifacts
    $test_tmp_dir = Dir.mktmpdir('goico-test-')
  end

  config.after(:suite) do
    # Clean up temporary directory
    FileUtils.remove_entry($test_tmp_dir) if $test_tmp_dir
  end

  config.before(:each) do
    # Reset I18n locale to default before each test
    Goico.set_locale(:en)
  end

  # Filter out temporarily skipped tests
  config.filter_run_when_matching :focus
end

# Disable stdout/stderr during tests to keep output clean
module SilenceOutput
  def silence_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original_stdout
  end

  def silence_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = original_stderr
  end
end

RSpec.configure do |config|
  config.include SilenceOutput
end