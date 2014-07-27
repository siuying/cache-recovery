require 'google-search'
require 'pry'
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
  end
end
