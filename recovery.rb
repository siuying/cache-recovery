require 'bundler'
Bundler.require :default
require 'sinatra'

require_relative './lib/cache-recovery'
require_relative './app/stores/recovery_store'

require_relative './app/helpers/search_helpers'
require_relative './app/helpers/recovery_helpers'
helpers SearchHelpers
helpers RecoveryHelpers

configure do
  set :domain, "thehousenews.com"
  set :store, RecoveryStore.new
end

# home page
get '/' do
  posts_count = settings.store.posts_count
  if posts_count == 0
    urls = site_search(settings.domain)
    settings.store.import(urls)
  end
  "Posts Count: #{posts_count}"
end

# list posts to be recovered
get '/pages' do
  settings.store.posts(1).collect do |data|
    data.to_s
  end
end

# list posts to be recovered, at page n
get %r{/pages/([0-9]+)} do
  content_type :text

  page = params[:captures].first.to_i
  settings.store.posts(page).collect do |data|
    data.to_s
  end
end

# get specific page via uuid
get '/posts/:uuid' do
  uuid = params[:uuid]
  post = settings.store.post(uuid)
  body = post[:body]
  url = post[:url]

  if body
    body
  else
    # page to be recovered
    "Post have not been recovered yet: #{captcha_url(url)}"
  end
end
