module SlackArena
  INFO = <<~EOS.freeze
    Are.na + Slack #{SlackArena::VERSION}

    © 2018 Daniel Doubrovkine & Contributors, MIT License
    https://twitter.com/dblockdotorg

    Service at #{SlackArena::Service.url}
    Open-Source at https://github.com/dblock/slack-arena
  EOS
end
