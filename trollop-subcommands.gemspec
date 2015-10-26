# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trollop/subcommands/version'

Gem::Specification.new do |spec|
  spec.name          = 'trollop-subcommands'
  spec.version       = Trollop::Subcommands::VERSION
  spec.authors       = ['Jason Liechty']
  spec.email         = ['jason.liechty@indigobio.com']

  spec.summary       = %q{Adds a subcommand framework to the Trollop command line parsing library.}
  spec.description   = %q{Though Trollop has the ability to support subcommands, I find myself
implementing the same logic repeatedly. The abstraction of this logic is
now in trollop-subcommands. This provides a framework for parsing
command line options for ruby scripts that have subcommands. The format
is 'script_name [global_options] subcommand [subcommand_options]'. The
framework supports all the typical scenarios around these type of
command line scripts. All that need to be specified are the trollop
configurations for the global options and each subcommand options. See
the readme for more information.}
  spec.homepage      = 'https://github.com/jwliechty/trollop-subcommands'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.3'

  spec.add_dependency 'trollop', '~> 2.1'
end
