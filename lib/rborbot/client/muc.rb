module Rborbot
  class Client
    class MUC
      extend Forwardable
      def_delegators  :@muc_client, :jid, :roster, :exit, :join, :nick, :nick=,
        :owner?, :room

      def initialize client
        @client     = client
        @muc_client = Jabber::MUC::MUCClient.new(client.client)
        setup_callbacks
      end

      def message body
        @muc_client.send Jabber::Message.new(nil, body)
      end


      private

      def setup_callbacks
        @muc_client.add_join_callback do |pres|
          @client.log["[#{jid.bare}] *#{pres.from}* has joined"]
        end
        @muc_client.add_leave_callback do |pres|
          @client.log["[#{jid.bare}] *#{pres.from}* has left"]
        end
        @muc_client.add_message_callback do |msg|
          @client.log["[#{jid.bare}] <#{msg.from.resource}> #{msg.body.inspect}"]
        end
      end
    end
  end
end
