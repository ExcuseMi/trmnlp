# frozen_string_literal: true

require 'faraday'
require 'uri'

require_relative 'mock_table'

module TRMNLP
  module Testing
    # `trmnlp test --page-proxy`: answers what the page in Firefox asks for, as MockProxy's table. The mocks
    # of the render being shown come first; anything else is sent on to its server. Firefox's own background
    # requests get an empty answer and are not recorded.
    class PageRequests
      ENV_KEY = 'TRMNLP_TEST_PAGE_PROXY'
      BROWSER_HOSTS = /(\A|\.)(mozilla\.(com|org|net)|firefox\.com)\z/
      UNREACHABLE_STATUS = 502
      TIMEOUT_SECONDS = 10
      FORWARDED = %w[accept accept-language authorization content-type cookie origin referer user-agent].freeze
      DROPPED = %w[connection content-encoding content-length keep-alive transfer-encoding].freeze

      # The mocks of the render now in the browser, as a MockTable; its requests are that screen's record.
      attr_writer :current

      def answer(verb, url, headers: {}, body: nil, **)
        return response(204, {}, '') if BROWSER_HOSTS.match?(host(url))

        table = @current
        return table.answer(verb, url, headers:, body:, via: :page) if table&.mocked?(verb, url, via: :page)

        live = send_on(verb, url, headers, body)
        table&.record({ method: verb, url:, headers:, body:, via: :page, mocked: false, aborted: false,
                        status: live.status })
        live
      end

      private

      def send_on(verb, url, headers, body)
        answer = connection.run_request(verb.downcase.to_sym, url, body, headers.slice(*FORWARDED))
        response(answer.status, answer.headers.to_h.transform_keys(&:downcase).except(*DROPPED), answer.body.to_s)
      rescue Faraday::Error, URI::Error
        response(UNREACHABLE_STATUS, { 'content-type' => 'text/plain' }, "trmnlp test: could not reach #{verb} #{url}")
      end

      def connection
        @connection ||= Faraday.new(request: { open_timeout: TIMEOUT_SECONDS, timeout: TIMEOUT_SECONDS })
      end

      def host(url)
        URI.parse(url).host.to_s
      rescue URI::Error
        ''
      end

      def response(status, headers, body) = MockTable::Response.new(status, headers, body, nil, {})
    end
  end
end
