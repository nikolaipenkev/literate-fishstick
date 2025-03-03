require 'redis'
require 'json'

class SEOStorage
  def initialize
    @redis = Redis.new
  end

  def save_seo_data(seo_data)
    @redis.set("seo:#{seo_data[:url]}", seo_data.to_json)
  end

  def export_results
    File.open("seo_results.txt", "w", encoding: "UTF-8") do |file|
      @redis.keys("seo:*").each do |key|
        row = JSON.parse(@redis.get(key))
        file.puts JSON.pretty_generate(row)
        file.puts "-" * 70  # Separator for readability
      end
    end
    puts "Results exported to seo_results.txt"
  end
end
