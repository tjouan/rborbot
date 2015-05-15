module Rborbot
  class Client
    extend Forwardable
    def_delegators  :@client, :connect, :on_exception, :register, :register_info
    def_delegator   :@client, :close, :disconnect
    def_delegator   :@client, :send, :xsend

    attr_reader :roster

    def initialize jid, log
      @log, @client = log, Jabber::Client.new(jid)
      setup_callbacks
    end

    def auth password
      @client.auth password
      setup_roster_callbacks
    end

    def presence type = :available
      @client.send Jabber::Presence.new.set_type(type).set_status('rborboting')
      :ok
    end

    def presence_subscribe jid
      @client.send Jabber::Presence.new.set_type(:subscribe).set_to(jid)
      :ok
    end

    def msg recipient, body
      @client.send Jabber::Message.new(recipient, body).tap { |o| o.type = :chat }
      :ok
    end

    def join channel
      muc = Jabber::MUC::SimpleMUCClient.new(@client)
      muc.on_message do |time, nick, text|
        @log["[#{channel}] <#{nick}> #{text.inspect}"]
      end
      muc.join Jabber::JID.new(channel)
      :ok
    end


    private

    def setup_callbacks
      @client.add_iq_callback do |iq|
        @log[iq.inspect]
      end
      @client.add_message_callback do |message|
        case message.type
        when :chat
          @log["<#{message.from}> #{message.body.inspect}"]
        else
          @log['%s <%s> %s' % [
            message.type,
            message.respond_to?(:from) ? message.from : '?',
            message.body
          ]]
        end
      end
    end

    def setup_roster_callbacks
      @roster = Jabber::Roster::Helper.new(@client)
      @roster.add_presence_callback do |item, oldpresence, presence|
        case presence.type
        when :unavailable
          @log["*#{presence.from}* is now unavailable"]
        else
          @log["*#{presence.from}* is now available"]
        end
      end
      @roster.add_subscription_callback do |item, presence|
        case presence.type
        when :subscribed
          @log["*#{presence.from}* has subscribed to us"]
        else
          @log["SUBSCRIPTION: #{item.inspect} / #{presence.inspect}"]
        end
      end
      @roster.add_subscription_request_callback do |item, presence|
        @log["SUBSCRIPTION REQUEST: #{item.inspect} / #{presence.inspect}"]
        @log["*#{presence.from}* requests subscribe to us"]
        roster.accept_subscription presence.from
        msg presence.from, <<-eoh
Hello #{presence.from},

  I'm allowing you to subscribe to my presence, as you requested.

regards,

rborbot the bot
        eoh
        presence_subscribe presence.from
      end
    end
  end
end
