$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
Dir["spec/support/**/*.rb"].each { |f| require_relative "../#{f}" }
require "rspec"
RSpec.configure do |c|
  c.expect_with :rspec do |e|
    e.syntax = :expect
  end
end
