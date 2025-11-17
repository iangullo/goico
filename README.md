# Goico - Railway-Inspired Rails Deployment
Inspired by the work of Alejandro Goicoechea, the innovative engineer behind
Talgo's unique railway car system that transformed rail travel, Goico is a Ruby
gem to automate the creation of deployable installer packages for Linux & MacOS
of ruby-on-rails applications.

## Naming Philosophy

Goico uses English for all class names, methods, and internal code to be accessible to international contributors, while preserving Spanish railway heritage through:

- **Gem name**: "Goico" honors Alejandro Goicoechea, Talgo's engineer
- **Metaphors**: Railway-themed terminology in documentation
- **I18n**: User messages available in multiple languages
- **Aliases**: Spanish method names available for convenience

Example:
```ruby
# Primary English API
Goico.travel("./myapp", type: "deb")

# Spanish aliases available
Goico.viajar("./myapp", tipo: "deb")


DEPENDENCIES
==
* Ruby v3

LICENSE
==
* Affero GPL-3.0-only

TODO
==
* Almost everything - starting from scratch.
