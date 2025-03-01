require 'redis'
require 'json'

class Cache
  def initialize
    @redis = Redis.new
  end

  def exists?(url)
    @redis.exists?("crawled:#{url}")
  end

  def mark_as_crawled(url)
    @redis.set("crawled:#{url}", "true")
  end

  def save_seo_data(url, seo_data)
    @redis.set("seo:#{url}", seo_data.to_json)
  end

  def get_seo_data(url)
    JSON.parse(@redis.get("seo:#{url}"))
  end

  def all_seo_data
    seo_keys = @redis.keys("seo:*")
    seo_keys.map do |key|
      url = key.sub("seo:", "")
      seo_data = JSON.parse(@redis.get(key))
      { url: url, seo_data: seo_data }
    end
  end

  def clear_cache
    clear_keys_matching('seo:*')
    clear_keys_matching('crawled:*')
  end

  private

  def clear_keys_matching(pattern)
    cursor = 0
    begin
      # Use SCAN command to iterate over keys in batches
      cursor, keys = @redis.scan(cursor, match: pattern)

      # Delete the keys in the current batch
      keys.each { |key| @redis.del(key) } if keys.any?
    end while cursor != "0" # Continue until all keys are processed
  end
end
