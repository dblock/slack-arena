require 'spec_helper'

describe 'Connect', :js, type: :feature do
  context 'without a user' do
    before do
      visit '/connect'
    end

    it 'requires a user' do
      expect(find_by_id('messages')).to have_text('Missing or invalid parameters.')
    end
  end

  [
    Faker::Internet.user_name,
    "#{Faker::Internet.user_name}'s",
    '💥 bob',
    'ваня',
    "\"#{Faker::Internet.user_name}'s\"",
    "#{Faker::Name.first_name} #{Faker::Name.last_name}",
    "#{Faker::Name.first_name}\n#{Faker::Name.last_name}",
    "<script>alert('xss');</script>",
    '<script>alert("xss");</script>'
  ].each do |user_name|
    context "user #{user_name}" do
      let!(:user) { Fabricate(:user, user_name: user_name) }

      it 'displays connect page and connects a user to their Arena account', vcr: { cassette_name: 'arena/oauth_token' } do
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postEphemeral).with(
          user: user.user_id,
          text: 'Successfully connected your Are.na account.',
          channel: 'C1'
        )
        allow(User).to receive(:where).with({ id: user.id }).and_return([user])
        expect(user).to receive(:connect!).with('code', 'C1').and_call_original
        state = CGI.escape([user.id.to_s, 'C1'].join(','))
        visit "/connect?state=#{state}&code=code"
        expect(find_by_id('messages')).to have_text("Successfully connected #{user.user_name.gsub("\n", ' ')} to Are.na. You can now return to Slack.")
        expect(user.reload.arena_token).to eq 'token'
      end
    end
  end
end
