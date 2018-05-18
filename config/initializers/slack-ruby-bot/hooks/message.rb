module SlackRubyBot
  module Hooks
    class Message
      # HACK: order command classes predictably
      def command_classes
        [
          SlackArena::Commands::Help,
          SlackArena::Commands::Info,
          SlackArena::Commands::Subscription
        ]
      end
    end
  end
end
