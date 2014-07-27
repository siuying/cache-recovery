require "cache/recovery/version"

module CacheRecovery
  # list all links from google of the supplied domain
  def self.list(domain)
    pages = []
    Google::Search::Web.new(:query => "site:#{domain}").each do |result|
      pages << {
        :title => result.title,
        :result => result.uri,
        :content => result.content,
        :cache_uri => result.cache_uri
      }
    end
    pages
  end
end
