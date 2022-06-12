module SlackArena
  INFO = <<~EOS.freeze
    Are.na + Slack #{SlackArena::VERSION}

    © 2018-2022 Daniel Doubrovkine, Vestris LLC & Contributors, MIT License
    https://vestris.com

    Service at #{SlackRubyBotServer::Service.url}
    Open-Source at https://github.com/dblock/slack-arena
  EOS
end
