# lib/tasks/goico.rake
require 'goico/generators/systemd'

namespace :goico do
  desc "Generate systemd service file"
  task :systemd, [:app_name] do |t, args|
    Goico::Generators::Systemd.start([args[:app_name]])
  end
end