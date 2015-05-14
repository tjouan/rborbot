module Rborbot
  class Env
    extend Forwardable
    def_delegators  :@input, :gets
    def_delegators  :@output, :print, :puts
    def_delegator   :logger, :info, :log

    attr_accessor :jid, :password

    def initialize input: StringIO.new, output: StringIO.new
      @input, @output = input, output
      @output.sync = true
    end

    def logger
      @logger ||= Logger.new(@output).tap do |o|
        o.level     = Logger::INFO
        o.formatter = proc do |severity, datetime, progname, message|
          "%s.%03i %s: %s\n" % [
            datetime.strftime('%FT%T'),
            datetime.usec / 1000,
            severity[0..0],
            message
          ]
        end
      end
    end
  end
end
