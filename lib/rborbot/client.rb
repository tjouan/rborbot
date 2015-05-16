module Rborbot
  class Client
    extend Forwardable
    def_delegators  :@client, :connect, :on_exception, :register, :register_info
    def_delegator   :@client, :close, :disconnect

    attr_reader :roster

    def initialize jid, log
      @log, @client = log, Jabber::Client.new(jid)
      setup_callbacks
    end

    def auth password
      @client.auth password
      setup_roster_callbacks
    end

    def presence type, status
      @client.send Jabber::Presence.new.set_type(type).set_status status
    end

    def presence_subscribe jid
      @client.send Jabber::Presence.new.set_type(:subscribe).set_to(jid)
    end

    def message_chat recipient, body
      @client.send Jabber::Message.new(recipient, body).tap { |o| o.type = :chat }
    end

    def muc_join channel
      muc = Jabber::MUC::SimpleMUCClient.new(@client)
      muc.on_message do |time, nick, text|
        @log["[#{channel}] <#{nick}> #{text.inspect}"]
      end
      muc.join Jabber::JID.new(channel)
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
      @roster.add_presence_callback do |item, oldpres, pres|
        oldpres = Jabber::Presence.new unless oldpres
        pres = Jabber::Presence.new unless pres
        jid = pres.from || oldpres.from
        log_msg = proc do |attr, a, b|
          "*#{jid}* #{attr} #{a.send(attr).inspect} -> #{b.send(attr).inspect}"
        end
        %i[type show status priority].each do |attr|
          if oldpres.send(attr) != pres.send(attr)
            @log[log_msg[attr, oldpres, pres]]
          end
        end
      end
      @roster.add_subscription_callback do |item, presence|
        case presence.type
        when :subscribed
          @log["*#{presence.from}* has subscribed to us"]
        when :unsubscribe
          @log["*#{presence.from}* has unsubscribed to us"]
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
