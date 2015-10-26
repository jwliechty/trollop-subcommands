# Trollop::Subcommands

This gem is an extension to [Trollop]. It provides a framework for commandline
scripts that use the following subcommand pattern

```bash
my_script [global options] command [command options]
```

## Usage

The framework abstracts setting up the Trollop parser to the sub command pattern
displayed above. Just provide the Trollop options blocks for the global options
and subcommands and you are good to go!

```ruby
#!/usr/bin/env ruby
require 'trollop/subcommands'

# do not specify in the Trollop block `stop_on` or `stop_on_unknown`
# as the subcommand framework will do that for you
Trollop::Subcommands::register_global do
  banner <<-END
Usage
  my_script [global options] COMMAND [command options]

COMMANDS
  list               List stuff
  create             Create stuff

Additional help
  my_script COMMAND -h

Options
  END
  opt :some_global_option, 'Some global option', type: :string, short: :none
end

Trollop::Subcommands::register_subcommand('list') do
  banner <<-END
Usage
  #{File.basename($0)} list [options]

This is the list command...

Options
  END
  opt :all, 'All the things', type: :boolean
end

Trollop::Subcommands::register_subcommand('create') do
  banner <<-END
Usage
  #{File.basename($0)} create [options]

This is the create command...

Options
  END
  opt :partial, 'blah blah', type: :boolean
  opt :name,    'blah blah', type: :string
end

result = Trollop::Subcommands::parse!


puts "Command was #{result.subcommand}"
puts "Global options were #{result.global_options}"
puts "Subcommand options were #{result.subcommand_options}"
```

The here documents for the banners can distract the code a bit. It can help to
abstract them to methods.

See the scenarios covered by the [spec].

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/jwliechty/trollop-subcommands.

## License

The gem is available as open source under the terms of the [MIT License]

[MIT License]: http://opensource.org/licenses/MIT
[spec]:        spec/trollop/subcommands_spec.rb
[Trollop]:     http://trollop.rubyforge.org/