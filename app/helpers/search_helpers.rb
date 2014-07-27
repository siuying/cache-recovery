require 'google-search'

module SearchHelpers
  def site_search(domain)
    options = {
      :size => :large,
      :query => "site:#{domain}"
    }

    search = Google::Search::Web.new(options)
    search.collect { |result| result.uri }
  end
end