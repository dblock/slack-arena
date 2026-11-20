module ArenaHelpers
  def arena_contents(items, has_more_pages: false)
    {
      data: items,
      meta: { current_page: 1, has_more_pages: has_more_pages }
    }.to_json
  end

  def arena_block(id, at, type: 'Image')
    {
      id: id,
      type: type,
      base_type: 'Block',
      title: "Block #{id}",
      created_at: at,
      user: { slug: 'owner', name: 'Owner' },
      connection: { connected_at: at, connected_by: { slug: 'connector', name: 'Connector' } }
    }
  end

  def stub_arena_contents(path, page, body)
    stub_request(:get, %r{\Ahttps://api\.are\.na/v3/#{path}/contents\?(?=.*page=#{page}(&|\z))})
      .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
  end
end

RSpec.configure do |config|
  config.include ArenaHelpers
end
