require 'spec_helper'

describe 'Connect', js: true, type: :feature do
  let(:user) { Fabricate(:user) }
  it 'connects a user to their Arena account', vcr: { cassette_name: 'arena/oauth_token' } do
    expect_any_instance_of(Slack::Web::Client).to receive(:chat_postEphemeral).with(
      user: user.user_id,
      text: 'Successfully connected your Are.na account.',
      channel: 'C1'
    )

    state = [user.id.to_s, 'C1'].join(',')
    visit "/connect?code=code&state=#{state}"
    expect(find('#messages', text: 'Successfully connected your Are.na account. You can now return to Slack.', visible: true))

    user.reload
    expect(user.arena_token).to eq 'token'
  end
end
