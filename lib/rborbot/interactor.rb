module Rborbot
  class Interactor
    PRY_PRINT = proc do |output, value, _pry_|
      next if value == :ok
      _pry_.pager.open do |pager|
        pager.print _pry_.config.output_prefix
        Pry::ColorPrinter.pp(value, pager, Pry::Terminal.width! - 1)
      end
    end

    PRY_PROMPT = %w[> *].map.with_index do |char, i|
      proc do |target_self, nest_level, pry|
        case target_self
        when self
          char + ' '
        else
          Pry::DEFAULT_PROMPT[i].call target_self, nest_level, pry
        end
      end
    end

    class << self
      def run env
        i = new env
        i.connect
        Pry.start i, print: PRY_PRINT, prompt: PRY_PROMPT
        i.terminate
      end
    end

    extend Forwardable
    def_delegators :@client, :register_info, :auth

    def initialize env
      @env, @client = env, Client.new(env.jid, method(:log).to_proc)
      @client.on_exception do |e|
        case e
        when IOError
          @client.connect
        else
          raise e
        end
      end
    end

    def log message
      @env.print "\e[1G"
      @env.log message
      Readline.refresh_line
    end

    def connect
      @client.connect
      if @env.password
        @client.auth @env.password
        presence
      end
    end

    def terminate
      @client.disconnect
    end

    def register
      @env.puts 'password:'
      password = @env.gets.chomp
      @client.register password
    end

    def chpass
      @env.puts 'password:'
      password = @env.gets.chomp
      @client.password = password
    end

    def presence type = :available, status = PRESENCE_STATUS
      @client.presence type, status
      :ok
    end

    def subscribe jid
      @client.presence_subscribe jid
      :ok
    end

    def msg recipient, body
      @client.message_chat recipient, body
      :ok
    end

    def join channel
      @client.muc_join channel
      :ok
    end

    def roster
      Hash[roster.items.map { |jid, item| [jid.to_s, item.subscription] }]
    end
  end
end
