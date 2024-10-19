require 'spec_helper'

describe User do
  describe '#find_by_slack_mention!' do
    let!(:user) { Fabricate(:user) }

    it 'finds by slack id' do
      expect(User.find_by_slack_mention!(user.team, "<@#{user.user_id}>")).to eq user
    end

    it 'finds by username' do
      expect(User.find_by_slack_mention!(user.team, user.user_name)).to eq user
    end

    it 'finds by username is case-insensitive' do
      expect(User.find_by_slack_mention!(user.team, user.user_name.capitalize)).to eq user
    end

    it 'requires a known user' do
      expect {
        User.find_by_slack_mention!(user.team, '<@nobody>')
      }.to raise_error SlackArena::Error, "I don't know who <@nobody> is!"
    end
  end

  describe '#find_create_or_update_by_slack_id!', vcr: { cassette_name: 'slack/user_info' } do
    let!(:team) { Fabricate(:team) }
    let(:client) { SlackRubyBot::Client.new }

    before do
      client.owner = team
    end

    context 'without a user' do
      it 'creates a user' do
        expect {
          user = User.find_create_or_update_by_slack_id!(client, 'whatever')
          expect(user).not_to be_nil
          expect(user.user_id).to eq 'whatever'
          expect(user.user_name).to eq 'username'
        }.to change(User, :count).by(1)
      end
    end

    context 'with a user' do
      let!(:user) { Fabricate(:user, team: team) }

      it 'creates another user' do
        expect {
          User.find_create_or_update_by_slack_id!(client, 'whatever')
        }.to change(User, :count).by(1)
      end

      it 'updates the username of the existing user' do
        expect {
          User.find_create_or_update_by_slack_id!(client, user.user_id)
        }.not_to change(User, :count)
        expect(user.reload.user_name).to eq 'username'
      end
    end
  end

  describe '#inform!' do
    let(:user) { Fabricate(:user, user_id: 'U0HLFUZLJ') }

    it 'sends message to all channels a user is a member of', vcr: { cassette_name: 'slack/conversations_list_conversations_members' } do
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
        message: 'message',
        channel: 'C0HNSS6H5',
        as_user: true
      ).and_return(ts: '1503435956.000247')
      expect(user.inform!(message: 'message').count).to eq(1)
    end
  end
end
