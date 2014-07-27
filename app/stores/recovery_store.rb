require 'uuid'
require 'sequel'
require 'logger'

class RecoveryStore
  attr_reader :uuid

  def initialize(db_uri="sqlite://./db/development.sqlite")
    @db = Sequel.connect(db_uri)
    require_relative './post'

    @db.loggers << Logger.new($stderr)
    @uuid = UUID.new
    setup
  end

  # add set of urls to the store as URL to be recovered
  def import(urls)
    @db.transaction do
      urls.each do |url|
        Post.insert(:uuid => @uuid.generate, :url => url)
      end
    end
  end

  def posts(page=1, per_page=30)
    return [] if page < 1
    Post.limit(per_page).offset((page-1)*per_page)
  end

  def posts_count
    Post.count
  end

  def post(uuid)
    Post.where(:uuid => uuid).first
  end

  private
  # setup database table
  def setup
    @db.create_table?(:posts) do
      String :uuid, :index => true
      String :url, :index => true
      String :captcha, :null => true
      String :title, :null => true
      String :body, :text => true, :null => true
      TrueClass :not_found, :default => false
    end
  end
end
