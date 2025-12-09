# Goico - Railway-Inspired Rails Deployment
Welcome to your new [Goico](https://github.com/iangullo/goico) gem!

Inspired by the work of Alejandro Goicoechea, the innovative engineer behind
Talgo's unique railway car system that transformed rail travel, Goico is a Ruby
gem to automate the creation of deployable installer packages for Linux & MacOS
of ruby-on-rails applications.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add goico
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install goico
```

## Usage

TODO: Almost everything - starting from scratch.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iangullo/goico. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/iangullo/goico/blob/main/CODE_OF_CONDUCT.md).

### Naming Philosophy

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

## Dependencies
* Ruby v3

## License

The gem is available as open source under the terms of the [Affero GPLv3 license](https://www.gnu.org/licenses/agpl-3.0.html).

## Code of Conduct

Everyone interacting in the Goico project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/icon/goico/blob/main/CODE_OF_CONDUCT.md).
