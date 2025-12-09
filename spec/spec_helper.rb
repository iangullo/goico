$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "rspec"
RSpec.configure do |c|
  c.expect_with :rspec do |e|
    e.syntax = :expect
  end
end
