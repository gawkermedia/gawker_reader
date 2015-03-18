# require 'kinja'
require 'digest/md5'

class Post < ActiveRecord::Base
  def self.fetch_and_create(url)
    kinja = Kinja::Client.new
    response = kinja.get_post(url)
    create_from_json response["data"] unless response["data"].nil?
  end

  def self.create_from_json(params)
    text = params["display"]
    post = create(
      {
        author: params["author"]["displayName"],
        kinja_id: params["id"],
        text: text,
        headline: params["headline"],
        publish_time: milli_to_date(params["publishTimeMillis"]),
        unique_hash: generate_hash(text),
        url: params["permalink"],
        big_image: params["facebookImage"],
        small_image: params["leftOfHeadline"],
        data: params,
        domain: get_domain(params["permalink"])
      }
    )
  end

  def preview_image
    small_image["src"]
  end

  def excerpt
    data["excerpt"]
  end

  private
  def self.milli_to_date(milliseconds)
    DateTime.strptime(milliseconds.to_s, '%Q')
  end
  def self.generate_hash(text)
    Digest::MD5.hexdigest text
  end

  def self.get_domain(link)
    link.match(/\.?(\w+\.com)/)[1]
  end
end