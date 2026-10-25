Are.na + Slack
==============

[![rubocop](https://github.com/dblock/slack-arena/actions/workflows/rubocop.yml/badge.svg)](https://github.com/dblock/slack-arena/actions/workflows/rubocop.yml)
[![test](https://github.com/dblock/slack-arena/actions/workflows/test.yml/badge.svg)](https://github.com/dblock/slack-arena/actions/workflows/test.yml)

Integrate Are.na into Slack. Hosted at [arena.playplay.io](https://arena.playplay.io/).

## Install

[![Add to Slack](https://platform.slack-edge.com/img/add_to_slack.png)](https://arena.playplay.io)

### Copyright & License

Copyright [Daniel Doubrovkine, Vestris LLC](https://www.vestris.com), 2018-2022

[MIT License](LICENSE)

### Website caching

Local website assets use `h asset_path('/img/example.png')` in ERB HTML
and `asset_path('/img/example.png').to_json` in JavaScript to include a
content hash. HTML revalidates with `private, no-cache`,
configured centrally through `SlackRubyBotServer.config.server_pages`.
Static files retain content ETags and timestamp validation;
do not add immutable or long-lived cache policies.
