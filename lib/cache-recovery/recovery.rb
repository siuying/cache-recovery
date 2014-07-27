require 'google-search'
require 'mechanize'
require 'cgi'
require 'set'
require 'json'

module CacheRecovery
  class Recovery
    attr_reader :domain, :links_to_fetch, :links_fetched, :links_not_found

    attr_reader :sleep_timer

    def initialize(domain, links_to_fetch=[], links_fetched=[], links_not_found=[], sleep_timer=1)
      @domain = domain

      @links_to_fetch = links_to_fetch
      @links_fetched = Set.new(links_fetched)
      @links_not_found = Set.new(links_not_found)

      @sleep_timer = sleep_timer
    end

    # Start the recovery.
    #
    # block - a block with three parameters: recovery(this object), url and body.
    # To be called each time a page is recovered. e.g. You can persists the page
    # each time a page is fetched.
    def start(&block)
      unless block_given?
        raise "you must supply a block"
      end

      # find initial set of pages to fetch via site search
      if @links_to_fetch.empty?
        @links_to_fetch += site_search(domain).collect {|item| URI(item[:url])}
          .select {|uri| uri.path != "" && uri.path != "/" }
          .collect {|uri| uri.to_s }
      end

      while link = @links_to_fetch.shift
        unless fetched?(link)
          begin
            result = fetch_cache_page(link)

            @links_fetched << link

            # for any links that are not already fetched, we should fetch them
            if result[:links]
              result[:links].each do |link|
                @links_to_fetch.push(link) unless fetched?(link)
              end
            end

            block.call(self, result[:url], result[:body])
          rescue Mechanize::ResponseCodeError => e
            if e.response_code == "404"
              puts "Link #{link} not found!"
              @links_not_found << link
            elsif e.response_code == "503"
              puts "Service unavailable: #{e}"
              raise e
            else
              puts "Unknown error: #{e}"
              raise e
            end
          end
        end

        sleep sleep_timer
      end
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

    # convert this object to a JSON data
    def to_json
      data = {
        :domain => self.domain,
        :links_to_fetch => self.links_to_fetch,
        :links_fetched => self.links_fetched.to_a,
        :links_not_found => self.links_not_found.to_a
      }
      JSON.pretty_generate(data)
    end

    # create a object from a JSON file created with to_json
    # json - the json data
    def self.from_json(json)
      data = JSON(json)
      Recovery.new(data["domain"], data["links_to_fetch"], data["links_fetched"], data["links_not_found"])
    end

    private

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

    # find the cache URL with a URL
    # url - the URL string to find cache for
    def cache_url(url)
      "http://www.google.com/search?q=cache:#{CGI.escape(url)}"
    end

  end
end
