require 'google-search'
require 'mechanize'
require 'cgi'

module CacheRecovery
  class Recovery
    # list all links from google of the supplied domain
    # domain - the domain to search for
    def self.list(domain)
      options = {
        :size => :large,
        :query => "site:#{domain}"
      }

      search = Google::Search::Web.new(options)
      search.collect do |result|
        {
          :title => result.title,
          :result => result.uri,
          :content => result.content,
          :cache_uri => result.cache_uri,
          :index => result.index
        }
      end
    end

    # fetch the cached page from google
    # url - the URL to be fetched
    # return a hash with following keys:
    #   - url the given URL
    #   - cached_url the cached url where we fetched from
    #   - links all links extracted from the url, which is from the same domain as url
    #   - body the html of the cached page
    def self.fetch_cache_page(url)
      agent = Mechanize.new
      uri = URI.parse(url)
      if uri.host.start_with?("www.google.com") || uri.host.start_with?("webcache.googleusercontent.com")
        raise "you cannot fetch a google page from google cache! url: #{url}"
      end

      cached_url = cache_url(url)
      page = agent.get(cached_url)
      body = page.body.force_encoding('utf-8')

      links = page.links
        .select {|link|
          link.uri && (link.uri.relative? || link.uri.host == uri.host)
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
        :links => body,
        :body => body
      }
    end

    private
    # find the cache URL with a URL
    # url - the URL string to find cache for
    def self.cache_url(url)
      "http://www.google.com/search?q=cache:#{CGI.escape(url)}"
    end

  end
end
