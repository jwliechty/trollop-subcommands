require 'spec_helper'

shared_examples 'a subcommand parser' do
  context 'when no args provided' do
    let(:args) { [] }
    it 'exits with failure' do
      expect_exit_fail(args)
    end
    it 'states no subcommand provided via stderr' do
      expected = "Error: No subcommand provided.\nTry --help for help.\n"
      expect_stderr(args, expected)
    end
  end
  context 'when global help parameter provided' do
    let(:args) { %w(--help) }
    it 'exits with success' do
      expect_exit_success(args)
    end
    it 'displays global help via stdout' do
      expect_stdout(args, global_help)
    end
  end
  context 'when invalid parameter given' do
    let(:args) { %w(--boom) }
    it 'exits with failure' do
      expect_exit_fail(args)
    end
    it 'states invalid parameter via stderr' do
      expected = "Error: unknown argument '--boom'.\nTry --help for help.\n"
      expect_stderr(args, expected)
    end
  end
  context 'when invalid subcommand given' do
    let(:args) { %w(boom) }
    it 'exits with failure' do
      expect_exit_fail(args)
    end
    it 'states unknown subcommand via stderr' do
      expected = "Error: Unknown subcommand 'boom'.\nTry --help for help.\n"
      expect_stderr(args, expected)
    end
  end
  context 'when valid subcommand given' do
    context 'with help parameter' do
      let(:args) { %W(#{subcommand} -h) }
      it 'exits with success' do
        expect_exit_success(args)
      end
      it 'displays subcommand help via stdout' do
        expect_stdout(args, subcommand_help)
      end
    end
    context 'with invalid parameter' do
      let(:args) { %w(list --boom) }
      it 'exits with failure' do
        expect_exit_fail(args)
      end
      it 'states invalid parameter via stderr' do
        expected = "Error: unknown argument '--boom' for command 'list'.\nTry --help for help.\n"
        expect_stderr(args, expected)
      end
    end
    context 'with valid parameters' do
      let(:args) { %W(#{subcommand} #{subcommand_arg}) }
      it 'returns the parse result' do
        actual = described_class::parse!(args)
        expect(actual.subcommand).to eql subcommand
        expect(actual.global_options).to eql global_options
        expect(actual.subcommand_options).to eql subcommand_options
      end
    end
  end

  def expect_exit_success(args)
    success = expect_exit(args)
    expect(success).to be true
  end

  def expect_exit_fail(args)
    success = expect_exit(args)
    expect(success).to be false
  end

  def expect_stdout(args, expected)
    expect_output(args, expected)
  end

  def expect_stderr(args, expected)
    expect_output(args, expected, destination: :to_stderr)
  end

  def expect_output(args, expected, destination: :to_stdout)
    expect{parse_with_exit_wrapped(args)}.to output(expected).send(destination)
  end

  def expect_exit(args)
    silence_around do
      actual = parse_with_exit_wrapped(args)
      unless [TrueClass, FalseClass].include?(actual.class)
        raise "Parsing did not call system exit for arguments: #{args}"
      end
      actual
    end
  end

  def parse_with_exit_wrapped(args)
    begin
      described_class::parse!(args)
    rescue SystemExit => e
      e.success?
    end
  end

  def silence_around
    original_stderr = $stderr
    original_stdout = $stdout
    null_stream = File.new('/dev/null', 'w')
    $stderr = null_stream
    $stdout = null_stream
    begin
      result = yield
    ensure
      $stderr = original_stderr
      $stdout = original_stdout
    end
    result
  end
end

describe Trollop::Subcommands do

  it 'has a version number' do
    expect(Trollop::Subcommands::VERSION).not_to be nil
  end

  describe '::parse!' do
    before :each do
      described_class.clear
    end
    context 'when global options not configured' do
      before :each do
        register_subcommand('list')
        register_subcommand('create')
      end
      it_behaves_like('a subcommand parser') do
        let(:global_help) { expected_default_global_help }
        let(:subcommand) { 'list' }
        let(:subcommand_help) { expected_list_help }
        let(:subcommand_arg) { '--list-opt' }
        let(:global_options) {{ help: false }}
        let(:subcommand_options) {{help: false, list_opt: true, list_opt_given: true}}
      end
    end
    context 'when global options are configured' do
      before :each do
        register_global_options
        register_subcommand('list')
        register_subcommand('create')
      end
      it_behaves_like('a subcommand parser') do
        let(:global_help) { expected_global_help }
        let(:subcommand) { 'list' }
        let(:subcommand_help) { expected_list_help }
        let(:subcommand_arg) { '--list-opt' }
        let(:global_options) { {help: false, some_global_option: false} }
        let(:subcommand_options) { {help: false, list_opt: true, list_opt_given: true} }
      end
    end
  end

  def register_global_options
    described_class::register_global do
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
      opt :some_global_option, 'Some global option', type: :boolean, short: :none
    end
  end

  def register_subcommand(name)
    described_class::register_subcommand(name) do
      banner <<-END
Usage
  #{File.basename($0)} #{name} [options]

This is the #{name} command...

Options
      END
      opt "#{name}_opt".to_sym, "Some #{name} option", type: :boolean
    end
  end

  def expected_default_global_help
    <<-END
Usage
  #{File.basename($0)} COMMAND [options]

COMMANDS
  list
  create

Additional help
  #{File.basename($0)} COMMAND -h

Options
  -h, --help    Show this message
    END
  end

  def expected_global_help
    <<-END
Usage
  my_script [global options] COMMAND [command options]

COMMANDS
  list               List stuff
  create             Create stuff

Additional help
  my_script COMMAND -h

Options
  --some-global-option    Some global option
  -h, --help              Show this message
    END
  end

  def expected_list_help
    <<-END
Usage
  #{File.basename($0)} list [options]

This is the list command...

Options
  -l, --list-opt    Some list option
  -h, --help        Show this message
    END
  end
end
