require_relative 'lib/goico/version'

Gem::Specification.new do |spec|
  spec.name          = "goico"
  spec.version       = Goico::VERSION
  spec.authors       = ["Iván González Angullo"]
  spec.email         = ["iangullo@gmail.com"]

  spec.summary       = "Goico - Railway-inspired Rails deployment"
  spec.description   = "Package Rails applications as system packages with Talgo-inspired reliability"
  spec.homepage      = "https://github.com/iangullo/goico"
  spec.license       = "Affero GPLv3"

  spec.files         = Dir["{bin,lib,locales,templates}/**/*", "README.md", "LICENSE.txt"]
  spec.bindir        = "bin"
  spec.executables   = ["goico"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  # Core dependencies
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "rainbow", "~> 3.0"
  spec.add_dependency "i18n", "~> 1.14"
  spec.add_dependency "fast_gettext", "~> 2.3" # Optional but recommended for CLI tools
  spec.add_dependency "git", "~> 1.18"

  # Packaging dependencies
  spec.add_dependency "fpm", "~> 1.14"
  spec.add_dependency "fpm-tools", "~> 0.0.1" # Optional helper tools

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.14.0"
end
