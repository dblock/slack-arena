# A block or a channel from an Are.na v3 channel or user contents list, rendered as a Slack attachment.
class ArenaItem
  BLOCK_KINDS = {
    'Attachment' => 'an attachment',
    'Embed' => 'an embed',
    'Image' => 'an image',
    'Link' => 'a link',
    'Text' => 'a text block'
  }.freeze

  attr_reader :item, :feed

  def initialize(item, feed)
    @item = item
    @feed = feed
  end

  # When the item was connected to the channel, or created by the user.
  def timestamp
    DateTime.rfc3339(connection&.[](:connected_at) || item[:created_at])
  end

  def to_slack
    {
      author_name: author_name,
      author_link: author_url,
      text: text,
      image_url: image_url,
      title: title,
      title_link: url
    }
  end

  def channel?
    item[:type] == 'Channel'
  end

  def connection
    item[:connection]
  end

  def author
    connection&.[](:connected_by) || item[:user] || item[:owner]
  end

  def author_name
    author&.[](:name) || author&.[](:username)
  end

  def author_url
    [Arena::URL, author&.[](:slug)].compact.join('/')
  end

  def title
    escape(item[:title])
  end

  def url
    if channel?
      [Arena::URL, item[:owner]&.[](:slug), item[:slug]].compact.join('/')
    else
      [Arena::URL, 'block', item[:id]].join('/')
    end
  end

  def image_url
    item[:image]&.[](:src)
  end

  def text
    case feed
    when ArenaChannel
      "#{channel? ? 'Connected' : 'Added'} to <#{feed.arena_url}|#{escape(feed.title)}>."
    else
      channel? ? "Created <#{url}|#{title}>." : "Added #{BLOCK_KINDS.fetch(item[:type], 'a block')}."
    end
  end

  private

  def escape(text)
    return unless text

    text.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  end
end
