module SlackArena
  module Commands
    class Help < SlackRubyBot::Commands::Base
      HELP = <<~EOS.freeze
        ```
        I am your friendly Are.na bot.

        Channels
        --------
        /arena connect [id]      - connect an Are.na channel
        /arena disconnect [id]   - disconnect an Are.na channel

        General
        -------
        help                     - get this helpful message
        subscription             - show subscription info
        info                     - bot info
        ```
EOS
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: [
          HELP,
          client.owner.reload.subscribed? ? nil : client.owner.subscribe_text
        ].compact.join("\n"))
        logger.info "HELP: #{client.owner}, user=#{data.user}"
      end
    end
  end
end
