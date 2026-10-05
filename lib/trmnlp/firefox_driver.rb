# frozen_string_literal: true

require 'selenium-webdriver'

module TRMNLP
  # Builds the headless Firefox driver that screenshots rendered plugins.
  # Shared by `trmnlp serve` (the PNG preview route) and `trmnlp build --png`.
  module FirefoxDriver
    module_function

    # proxy: "host:port" of the proxy `trmnlp test` answers the page's requests with. It opens HTTPS with
    # certificates of its own, which Firefox is then told to accept.
    def build(proxy: nil)
      Selenium::WebDriver.for(:firefox, options: options(proxy:)).tap do |driver|
        driver.manage.window.maximize
      end
    end

    def options(proxy: nil)
      Selenium::WebDriver::Firefox::Options.new(web_socket_url: true).tap do |opts|
        opts.add_argument('--headless')
        opts.add_argument('--disable-web-security')
        next unless proxy

        opts.proxy = Selenium::WebDriver::Proxy.new(http: proxy, ssl: proxy)
        opts.accept_insecure_certs = true
      end
    end
  end
end
