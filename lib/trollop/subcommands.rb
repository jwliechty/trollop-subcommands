require 'trollop'
require 'trollop/subcommands/version'

module Trollop
  module Subcommands

    ## Register the options block for parsing the global options. If
    ## not invoked, a default options block with a bare-bones usage
    ## message will be used. No need to specify `stop_on` or
    ## `stop_on_unknown` as that is done automatically at the time of
    ## parsing.
    def register_global(&trollop_block)
      parser.register_global(&trollop_block)
    end

    ## Register the options block for a given subcommand. If the
    ## subcommand does not need options, one should still be
    ## provided specifying the banner. The banner displays when
    ## the when the followng arguments are given:
    ##   my_script my_subcommand -h
    def register_subcommand(command, &trollop_block)
      parser.register_subcommand(command, &trollop_block)
    end

    ## Where the magic happens. Once all the subcommands and optionally
    ## the global options are registered, invoke this method for the
    ## command line parsing to begin. The result of this method
    ## invocation is a struct containing the `global_options` (hash),
    ## `subcommand` (string), and `subcommand_options` (hash).
    def parse!(args=ARGV)
      parser.parse!(args)
    end

    ## @private This is simply a helper method for the other publicly
    ## exposed methods.
    def parser
      @parser ||= Parser.new
    end

    ## @private Used for the specs as arguments are parsed multiple
    ## times in one process. For scripts, parsing usually occurs once.
    def clear
      @parser = nil
    end

    class Parser
      def initialize
        @subcommand_parsers_lookup = {}
      end

      def register_global(&trollop_block)
        @global_parser = create_parser(&trollop_block)
      end

      def register_subcommand(command, &trollop_block)
        @subcommand_parsers_lookup[command.to_s] = trollop_block
      end

      def parse!(args=ARGV)
        @global_parser ||= default_global_parser
        @global_parser.stop_on(subcommands)
        @global_parser.stop_on_unknown
        Trollop::with_standard_exception_handling(@global_parser) do
          global_options = @global_parser.parse(args)
          cmd = parse_subcommand(args)
          cmd_options = parse_subcommand_options(args, cmd)
          Result.new(global_options, cmd, cmd_options)
        end
      end

      private

      def default_global_parser
        script_name = File.basename($0)
        commands = @subcommand_parsers_lookup.keys.map(&:to_s)
        create_parser do
          banner <<-END
Usage
  #{script_name} COMMAND [options]

COMMANDS
  #{commands.join("\n  ")}

Additional help
  #{script_name} COMMAND -h

Options
          END
        end
      end

      def create_parser(&block)
        ::Trollop::Parser.new(&block)
      end

      def subcommands
        @subcommand_parsers_lookup.keys
      end

      def parse_subcommand(args)
        cmd = args.shift
        raise ::Trollop::CommandlineError.new('No subcommand provided') unless cmd
        cmd
      end

      def parse_subcommand_options(args, cmd)
        block = @subcommand_parsers_lookup[cmd]
        raise ::Trollop::CommandlineError.new("Unknown subcommand '#{cmd}'") unless block
        cmd_parser = ::Trollop::Parser.new(&block)
        ::Trollop::with_standard_exception_handling(cmd_parser) do
          begin
          result = cmd_parser.parse(args)
          rescue CommandlineError => e
            raise CommandlineError.new("#{e.message} for command '#{cmd}'")
          end
          result
        end
      end

      Result = Struct.new(:global_options, :subcommand, :subcommand_options)
    end

    module_function :register_global, :register_subcommand, :parse!, :parser, :clear
  end
end
