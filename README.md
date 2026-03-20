Are.na + Slack
==============

[![rubocop](https://github.com/dblock/slack-arena/actions/workflows/rubocop.yml/badge.svg)](https://github.com/dblock/slack-arena/actions/workflows/rubocop.yml)
[![test](https://github.com/dblock/slack-arena/actions/workflows/test.yml/badge.svg)](https://github.com/dblock/slack-arena/actions/workflows/test.yml)

Integrate Are.na into Slack. Hosted at [arena.playplay.io](https://arena.playplay.io/).

## API Status

This project now uses direct Are.na API calls instead of the `arena` gem.

User and channel lookups, account channel listing, and block creation use Are.na v3 endpoints. Search and activity feeds currently remain on legacy endpoints for compatibility with the existing Slack experience.

## Install

[![Add to Slack](https://platform.slack-edge.com/img/add_to_slack.png)](https://arena.playplay.io)

### Copyright & License

Copyright [Daniel Doubrovkine, Vestris LLC](https://www.vestris.com), 2018-2022

[MIT License](LICENSE)
