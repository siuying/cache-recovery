require 'mechanize'
require 'set'
require 'json'

module CacheRecovery
  class Recovery
    attr_reader :domain, :links_to_fetch, :links_fetched, :links_not_found

    attr_reader :sleep_timer

    def initialize(domain)
      @domain = domain
      @links_to_fetch = []
      @links_fetched = []
      @links_not_found = []
    end

    def fetched?(url)
      @links_fetched.include?(url) || @links_not_found.include?(url)
    end

    # list all links from google of the supplied domain
    # domain - the domain to search for
    def site_search(domain)
      options = {
        :size => :large,
        :query => "site:#{domain}"
      }

      search = Google::Search::Web.new(options)
      search.collect do |result|
        {
          :title => result.title,
          :url => result.uri,
          :content => result.content,
          :cache_uri => result.cache_uri,
          :index => result.index
        }
      end
    end

    def sorry_url(url)
      "http://ipv4.google.com/sorry/IndexRedirect?continue=#{cache_url(url)}"
    end

    # find the cache URL with a URL
    # url - the URL string to find cache for
    def cache_url(url)
      "http://webcache.googleusercontent.com/search?q=cache:#{CGI.escape(url)}"
    end

    # fetch the cached page from google
    # url - the URL to be fetched
    # return a hash with following keys:
    #   - url the given URL
    #   - cached_url the cached url where we fetched from
    #   - links all links extracted from the url, which is from the same domain as url
    #   - body the html of the cached page
    def fetch_cache_page(url)
      agent = Mechanize.new { |agent|
        agent.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:30.0) Gecko/20100101 Firefox/30.0'
      }
      uri = URI.parse(url)
      if uri.host.start_with?("www.google.com") || uri.host.start_with?("webcache.googleusercontent.com")
        raise "you cannot fetch a google page from google cache! url: #{url}"
      end

      cached_url = cache_url(url)
      page = agent.get(cached_url)
      body = page.body.force_encoding('utf-8')

      links = page.links
        .select {|link|
          link.uri && ((link.uri.relative? && link.uri.path != "") || link.uri.host == uri.host)
        }
        .collect do |link|
          if link.uri.relative?
            URI.join(uri, link.uri).to_s
          else
            link.uri.to_s
          end
        end

      {
        :url => url,
        :cached_url => cached_url,
        :links => links,
        :body => body
      }
    end
  end
end
