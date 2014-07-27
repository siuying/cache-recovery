require 'cgi'
require 'open-uri'
require 'httparty'
require 'nokogiri'
require 'mechanize'

module RecoveryHelpers
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:30.0) Gecko/20100101 Firefox/30.0"

  # Get a captcha URL
  def captcha_url(url)
    "http://ipv4.google.com/sorry/IndexRedirect?continue=#{cache_url(url)}"
  end

  # find the cache URL with a URL
  # url - the URL string to find cache for
  def cache_url(url)
    "http://webcache.googleusercontent.com/search?q=cache:#{url}"
  end

  def captcha_page(url)
    agent = Mechanize.new
    agent.user_agent = USER_AGENT

    captcha_url = captcha_url(url)
    page = fetch_page(agent, captcha_url)
    uri = URI.parse(captcha_url)

    captcha_image = page.search('img').first["src"] rescue nil
    captcha_image_url = URI.join(uri, captcha_image).to_s if captcha_image
    captcha_id = page.search("//input[@name='id']").first["value"] rescue nil
    captcha_continue = page.search("//input[@name='continue']").first["value"] rescue nil

    page = fetch_page(agent, captcha_image_url)
    data = Base64.encode64(page.body).tr("\n", "")
    image_data = "data:image/jpg;base64,#{data}"
    cookies = save_cookie_jar(agent)

    {
      :image_data => image_data,
      :image_url => captcha_image_url,
      :id => captcha_id,
      :continue => captcha_continue,
      :cookies => cookies
    }
  end

  def fetch_webcache(captcha_id, captcha_continue, cookies, captcha_value)
    agent = Mechanize.new
    agent.user_agent = USER_AGENT
    agent.cookie_jar.load_cookiestxt(StringIO.new(cookies, "r"))
    url = "http://ipv4.google.com/sorry/CaptchaRedirect?continue=#{CGI.escape(captcha_continue)}&id=#{captcha_id}&captcha=#{captcha_value}&submit=Submit"
    puts url
    page = fetch_page(agent, url)
  end

  private

  def save_cookie_jar(agent)
    io = StringIO.new
    agent.cookie_jar.to_a.each do |cookie|
      fields = []
      fields[0] = cookie.domain
      fields[1] = cookie.domain =~ /^\./ ? "TRUE" : "FALSE"
      fields[2] = cookie.path
      fields[3] = cookie.secure == true ? "TRUE" : "FALSE"
      fields[4] = cookie.expires.to_i.to_s
      fields[5] = cookie.name
      fields[6] = cookie.value
      io.puts(fields.join("\t"))
    end
    io.string
  end

  def fetch_page(agent, url)
    begin
      return agent.get(url)
    rescue Mechanize::ResponseCodeError => exception
      if exception.response_code != "503"
        raise exception
      else
        return exception.page
      end
    end
  end
end
