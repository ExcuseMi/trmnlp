# frozen_string_literal: true

require 'spec_helper'
require 'trmnlp/testing/page_requests'

RSpec.describe TRMNLP::Testing::PageRequests do
  subject(:requests) { described_class.new.tap { it.current = table } }

  let(:table) { TRMNLP::Testing::MockTable.new(mocks) }
  let(:mocks) { { 'https://api.test/*' => { json: { n: 1 } }, '*' => { status: 500, body: '' } } }

  before do
    stub_request(:get, 'https://cdn.test/lib.js')
      .to_return(body: 'library', headers: { 'Content-Type' => 'text/javascript', 'Content-Encoding' => 'gzip' })
  end

  it "answers from the render's mocks first" do
    expect(requests.answer('GET', 'https://api.test/items')).to have_attributes(status: 200, body: '{"n":1}')
  end

  it 'records a mocked request on the screen, as the page asked for it' do
    requests.answer('GET', 'https://api.test/items')

    expect(table.requests).to contain_exactly(include(url: 'https://api.test/items', via: :page, mocked: true))
  end

  it 'sends anything else on to its server, past a mock for every url' do
    expect(requests.answer('GET', 'https://cdn.test/lib.js'))
      .to have_attributes(status: 200, body: 'library', headers: { 'content-type' => 'text/javascript' })
  end

  it 'records it as not mocked' do
    requests.answer('GET', 'https://cdn.test/lib.js')

    expect(table.requests).to contain_exactly(include(url: 'https://cdn.test/lib.js', mocked: false, status: 200))
  end

  it "sends the page's own headers and body on" do
    sent = stub_request(:post, 'https://cdn.test/log').with(body: 'a=1', headers: { 'User-Agent' => 'Firefox' })
    requests.answer('POST', 'https://cdn.test/log', headers: { 'user-agent' => 'Firefox' }, body: 'a=1')

    expect(sent).to have_been_requested
  end

  it "answers Firefox's own requests with nothing, and leaves them off the record" do
    response = requests.answer('GET', 'https://firefox.settings.services.mozilla.com/v1/buckets')

    expect([response.status, table.requests]).to eq([204, []])
  end

  context 'when a server cannot be reached' do
    before { stub_request(:get, 'https://cdn.test/lib.js').to_timeout }

    it 'answers 502, which the page reports as a file that failed to load' do
      expect(requests.answer('GET', 'https://cdn.test/lib.js')).to have_attributes(status: 502)
    end

    it 'records it' do
      requests.answer('GET', 'https://cdn.test/lib.js')

      expect(table.requests).to contain_exactly(include(status: 502, mocked: false))
    end
  end

  it 'answers before any screen is shown' do
    requests.current = nil

    expect(requests.answer('GET', 'https://cdn.test/lib.js')).to have_attributes(status: 200)
  end
end
