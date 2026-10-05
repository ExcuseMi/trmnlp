# frozen_string_literal: true

require 'spec_helper'
require 'trmnlp/firefox_driver'

RSpec.describe TRMNLP::FirefoxDriver do
  describe '.options' do
    subject(:options) { described_class.options }

    it 'runs Firefox headless with web security disabled' do
      expect(options.args).to include('--headless', '--disable-web-security')
    end

    it 'opens a WebDriver BiDi connection, which sets viewports narrower than a window can be' do
      expect(options.web_socket_url).to be(true)
    end

    it 'uses no proxy' do
      expect(options.proxy).to be_nil
    end

    context 'with a proxy' do
      subject(:options) { described_class.options(proxy: '127.0.0.1:4000') }

      it 'sends HTTP and HTTPS through it, and accepts the certificates it answers HTTPS with' do
        expect([options.proxy.http, options.proxy.ssl, options.accept_insecure_certs])
          .to eq(['127.0.0.1:4000', '127.0.0.1:4000', true])
      end
    end
  end
end
