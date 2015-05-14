module Rborbot
  class Client
    extend Forwardable
    def_delegators  :@client, :connect
    def_delegator   :@client, :close, :disconnect
    def_delegator   :@client, :send, :xsend

    def initialize env
      @env, @client = env, Jabber::Client.new(env.jid)
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

    def roster
      Jabber::Roster::Helper.new(@client)
    end

    def msg recipient, body
      @client.send Jabber::Message.new(recipient, body).tap { |o| o.type = :chat }
      :ok
    end

    def join channel
      muc = Jabber::MUC::SimpleMUCClient.new(@client)
      muc.on_message do |time, nick, text|
        @env.log "[#{channel}] <#{nick}> #{text.inspect}"
      end
      muc.join Jabber::JID.new(channel)
      :ok
    end


    private

    def setup_callbacks
      @client.add_iq_callback do |iq|
        @env.log iq.inspect
      end
      @client.add_message_callback do |message|
        case message.type
        when :chat
          @env.log "<#{message.from}> #{message.body.inspect}"
        else
          @env.log '%s <%s> %s' % [
            message.type,
            message.respond_to?(:from) ? message.from : '?',
            message.body
          ]
        end
      end
    end

    def setup_roster_callbacks
      roster = Jabber::Roster::Helper.new(@client)
      roster.add_update_callback do |olditem, item|
        @env.log "ROSTER UPDATE: #{olditem.inspect} -> #{item.inspect}"
      end
      roster.add_presence_callback do |item, oldpresence, presence|
        @env.log "PRESENCE UPDATE: #{item} / #{oldpresence.inspect} -> #{presence.inspect}"
      end
      roster.add_subscription_callback do |item, presence|
        @env.log "SUBSCRIPTION: #{item.inspect} / #{presence.inspect}"
      end
      roster.add_subscription_request_callback do |item, presence|
        @env.log "SUBSCRIPTION REQUEST: #{item.inspect} / #{presence.inspect}"
        @env.log "*#{presence.from}* requests subscribe to us"
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
