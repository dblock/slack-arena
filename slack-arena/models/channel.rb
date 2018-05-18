class Channel
  include Mongoid::Document
  include Mongoid::Timestamps

  field :arena_id, type: String
  field :title, type: String

  belongs_to :team
  field :channel_id, type: String
  field :channel_name, type: String

  index({ team_id: 1, arena_id: 1, channel_id: 1 }, unique: true)

  def to_s
    "arena_id=#{arena_id}, title=#{title}, channel_id=#{channel_id}, channel_name=#{channel_name}, #{team}"
  end

  def repost!; end

  def self.attrs_from_arena(channel)
    {
      arena_id: channel.id,
      title: channel.title
    }
  end

  def channel_mention
    "<##{channel_id}>"
  end

  def to_slack
    {
      attachments: [{
        title: title
      }]
    }
  end

  def sync_last_arena_item!; end

  def sync_new_arena_items!; end
end
