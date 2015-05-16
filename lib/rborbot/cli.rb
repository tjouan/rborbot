module Rborbot
  class CLI
    ArgumentError = Class.new(ArgumentError)

    USAGE = "Usage: #{File.basename $0} [options]".freeze

    EX_USAGE    = 64
    EX_SOFTWARE = 70

    class << self
      def run arguments, stdin: $stdin, stdout: $stdout, stderr: $stderr
        new(arguments, stdin: stdin, stdout: stdout).tap do |o|
          o.parse_arguments!
          o.run
        end
      rescue ArgumentError => e
        stderr.puts e
        exit EX_USAGE
      rescue RuntimeError => e
        stderr.puts "#{e.class.name}: #{e.message}"
        stderr.puts e.backtrace.map { |e| '  %s' % e }
        exit EX_SOFTWARE
      end
    end

    def initialize args, stdin: $stdin, stdout: $stdout
      @arguments  = args
      @env        = Env.new(input: stdin, output: stdout)
    end

    def parse_arguments!
      option_parser.parse! @arguments
      fail ArgumentError, option_parser if @arguments.any?
    rescue OptionParser::InvalidOption => e
      fail ArgumentError, option_parser
    end

    def run
      Interactor.run(@env)
    end


    private

    def option_parser
      OptionParser.new do |opts|
        opts.banner = USAGE
        opts.separator ''
        opts.separator 'options:'

        opts.on '-d', '--debug', 'enable debug mode' do
          Jabber.debug = true
        end
        opts.on '-j', '--jid JID', 'specify JID' do |jid|
          @env.jid = jid
        end
        opts.on '-p', '--password PATH', 'specify password file path' do |path|
          @env.password = File.read(path).chomp
        end
        opts.on '-h', '--help', 'print this message' do
          @env.print opts
          exit
        end
        opts.on '-V', '--version', 'print version' do
          @env.puts VERSION
          exit
        end
      end
    end
  end
end
