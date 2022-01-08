## Development and Production

You may want to watch [Your First Slack Bot Service video](http://code.dblock.org/2016/03/11/your-first-slack-bot-service-video.html) first.

### Prerequisites

Ensure that you can build the project and run tests. You will need these.

- [MongoDB](https://docs.mongodb.com/manual/installation/)
- [Geckodriver](https://github.com/mozilla/geckodriver)

```
bundle install
bundle exec rake
```

All tests should pass.

### Slack Team

Create a Slack team [here](https://slack.com/create).

### Slack App

Create an app [here](https://api.slack.com/apps). This gives you a client ID and a client secret.

Under _Features/OAuth & Permissions_, configure the redirect URL to `http://localhost:5000`. For production this will be something like `https://arena.playplay.io/`.

Add the following OAuth Permission Scope.

* **bot**: user with the username @arena, add the ability for people to direct message or mention @arena.
* **commands**: add shortcuts and/or slash commands that people can use.

Under _Slash Commands_, add `/arena`, with a `Search, connect and follow.` description.

### Are.na App

Create an app [here](https://dev.are.na/oauth/applications). This gives you an Are.na client ID and a client secret.

### Slack and Are.na Keys

Locally, create a `.env` file and copy Slack and Are.na keys into it. In production set those as ENV values.

```
SLACK_CLIENT_ID=
SLACK_CLIENT_SECRET=
SLACK_VERIFICATION_TOKEN=
ARENA_CLIENT_ID=
ARENA_CLIENT_SECRET=
```

### Mailchimp

The bot can add those who install the bot to a Mailchimp list. Optionally, set the following keys.

```
MAILCHIMP_API_KEY=
MAILCHIMP_LIST_ID=
```

### Stripe Keys

For upgrading, premium and payment-related functions you need a [Stripe](https://www.stripe.com) account and test keys.

```
STRIPE_API_PUBLISHABLE_KEY=pk_test_key
STRIPE_API_KEY=sk_test_key
```

### Start the Bot

```
$ foreman start

08:54:07 web.1  | started with pid 32503
08:54:08 web.1  | I, [2017-08-04T08:54:08.138499 #32503]  INFO -- : listening on addr=0.0.0.0:5000 fd=11
```

Navigate to [localhost:5000](http://localhost:5000).

### ngrok tunnel

To use Slash commands and actions, start an [ngrok tunnel](https://dashboard.ngrok.com/get-started/setup). 

```
ngrok localhost 5000
```

This will give you a URL, e.g. `https://29bd-71-167-106-233.ngrok.io`. Navigate to this URL, it should serve the bot's website.

Configure a slash command, `/arena` in the Slack app to point to `https://29bd-71-167-106-233.ngrok.io/api/slack/command`.

Configure the Request URL in Interactivity & Shortcuts to `https://29bd-71-167-106-233.ngrok.io/api/slack/action/`.  

## Production

### MongoDB

Set `MONGO_URL` to a MongoDB instance.

Set keys as environment variables. Don't mix test and production Slack and Are.na apps or databases. Use different keys.

Push the bot code to production.
