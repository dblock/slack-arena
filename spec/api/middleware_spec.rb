require 'spec_helper'

describe Api::Middleware do
  include Rack::Test::Methods

  let(:app) { described_class.instance }

  %w[/ /help.html /privacy.html /connect.html /subscribe.html /update_cc.html].each do |path|
    it "versions local assets and revalidates #{path}" do
      get path

      assets = Capybara.string(last_response.body).all('script[src], link[href], img[src]', visible: :all)
      urls = assets.map { |asset| asset[:src] || asset[:href] }.reject { |url| url.start_with?('http:', 'https:', '//') }
      expect(last_response.status).to eq 200
      expect(last_response.headers['Cache-Control']).to eq 'private, no-cache'
      expect(urls).not_to be_empty
      expect(urls).to all(match(%r{\A/.+\?v=[a-f0-9]{64}\z}))
    end
  end

  it 'versions Stripe images in JavaScript and HTML attributes' do
    image = "/img/icon.png?v=#{Digest::SHA256.file('public/img/icon.png').hexdigest}"
    get '/subscribe.html'
    expect(last_response.body).to include("image: #{image.to_json}")

    get '/update_cc.html'
    expect(Capybara.string(last_response.body).find('script[data-image]', visible: :all)['data-image']).to eq image
  end

  it 'retains content ETags and timestamp validation for static files' do
    get '/scripts/arena.js'
    etag = last_response.headers['ETag']
    expect(etag).to eq %("#{Digest::SHA256.file('public/scripts/arena.js').hexdigest}")
    expect(last_response.headers['Cache-Control']).to be_nil

    get '/scripts/arena.js', {}, 'HTTP_IF_NONE_MATCH' => etag
    expect(last_response.status).to eq 304
    expect(last_response.body).to be_empty

    get '/scripts/arena.js', {}, 'HTTP_IF_MODIFIED_SINCE' => File.mtime('public/scripts/arena.js').httpdate
    expect(last_response.status).to eq 304
  end

  it 'ignores a matching mtime when the content ETag is stale' do
    get '/scripts/arena.js', {}, 'HTTP_IF_NONE_MATCH' => '"old-content"',
                                 'HTTP_IF_MODIFIED_SINCE' => File.mtime('public/scripts/arena.js').httpdate

    expect(last_response.status).to eq 200
    expect(last_response.body).to eq File.read('public/scripts/arena.js')
  end
end
