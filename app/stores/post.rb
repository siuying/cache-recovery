require 'sequel/model'

class Post < Sequel::Model
  set_primary_key [:uuid]

  def fetched?
    self.not_found || self.body
  end

  def to_s
    "<Post url=#{url}, uuid=#{uuid}, fetched=#{fetched? ? "true" : "false" }>"
  end
end
