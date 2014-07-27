require 'cgi'

module CacheRecovery
  module Helpers
    def sorry_url(url)
      "http://ipv4.google.com/sorry/IndexRedirect?continue=#{cache_url(url)}"
    end

    # find the cache URL with a URL
    # url - the URL string to find cache for
    def cache_url(url)
      "http://webcache.googleusercontent.com/search?q=cache:#{CGI.escape(url)}"
    end
  end
end