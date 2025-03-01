require 'nokogiri'
require 'httparty'
require 'uri'
require 'concurrent'
require 'redis'
require 'json'
require 'csv'
require 'net/http'

class UltimateSEOCrawler
  def initialize(start_url, max_depth = 2, thread_pool_size = 10)
    @start_url = start_url
    @max_depth = max_depth
    @visited_urls = Concurrent::Map.new
    @thread_pool = Concurrent::FixedThreadPool.new(thread_pool_size)
    @redis = Redis.new
  end

  def crawl(url = @start_url, depth = 0)
    return if depth > @max_depth || @redis.exists?("crawled:#{url}")

    @visited_urls[url] = true
    @redis.set("crawled:#{url}", "true")
    @thread_pool.post { process_page(url, depth) }
  end

  def process_page(url, depth)
    puts "Crawling: #{url}"
    start_time = Time.now
    response = HTTParty.get(url, follow_redirects: true, timeout: 10) rescue nil
    return unless response&.success?

    load_time = Time.now - start_time
    document = Nokogiri::HTML(response.body)
    save_seo_data(document, url, response.headers, load_time, response.body.bytesize)
    extract_links(document, url).each { |link| crawl(link, depth + 1) }
  end

  def save_seo_data(document, url, headers, load_time, page_size)
    title = document.at('title')&.text&.strip || "No Title"
    title_length = title.length

    meta_desc = document.at('meta[name="description"]')&.[]('content')&.strip || "No Meta Description"
    meta_desc_length = meta_desc.length

    h1 = document.at('h1')&.text&.strip || "No H1"
    h2 = document.css('h2').map { |h| h.text.strip }.join(" | ")
    h3 = document.css('h3').map { |h| h.text.strip }.join(" | ")

    canonical = document.at('link[rel="canonical"]')&.[]('href') || url

    robots_meta = document.at('meta[name="robots"]')&.[]('content') || headers["X-Robots-Tag"] || "No Robots Meta"

    has_schema = !document.css('script[type="application/ld+json"]').empty? ||
      !document.at('meta[property="og:type"]').nil? ||
      !document.at('meta[name="twitter:card"]').nil?

    images = document.css('img')
    missing_alt = images.count { |img| img['alt'].nil? || img['alt'].strip.empty? }
    total_images = images.size
    alt_missing_percentage = total_images.zero? ? 0 : ((missing_alt.to_f / total_images) * 100).round(2)

    word_count = document.text.split(/\s+/).size

    links = document.css('a[href]').map { |a| a['href'] }
    internal_links = links.select { |l| l.start_with?('/') || l.include?(URI.parse(@start_url).host) }.size
    external_links = links.size - internal_links

    broken_links = links.count { |link| link_broken?(link) }

    is_https = url.start_with?("https")

    has_google_analytics = !!document.at('script[src*="google-analytics.com"]')
    has_google_tag_manager = !!document.at('script[src*="googletagmanager.com"]')

    seo_data = {
      url: url,
      title: title,
      title_length: title_length,
      meta_description: meta_desc,
      meta_description_length: meta_desc_length,
      h1: h1,
      h2: h2,
      h3: h3,
      canonical: canonical,
      robots_meta: robots_meta,
      has_schema: has_schema,
      missing_alt_percentage: "#{alt_missing_percentage}%",
      word_count: word_count,
      internal_links: internal_links,
      external_links: external_links,
      broken_links: broken_links,
      load_time: "#{load_time.round(2)}s",
      page_size: "#{(page_size / 1024.0).round(2)} KB",
      is_https: is_https,
      has_google_analytics: has_google_analytics,
      has_google_tag_manager: has_google_tag_manager
    }

    @redis.set("seo:#{url}", seo_data.to_json)
  end

  def link_broken?(url)
    return false if url.nil? || url.empty?

    uri = URI.parse(url) rescue nil
    return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    res = Net::HTTP.get_response(uri) rescue nil
    res.nil? || res.code.to_i >= 400
  end

  def extract_links(document, base_url)
    document.css('a[href]').map { |a| normalize_url(a['href'], base_url) }.compact.uniq
  end

  def normalize_url(link, base_url)
    uri = URI.parse(link) rescue nil
    return nil unless uri
    uri.relative? ? URI.join(base_url, uri).to_s : uri.to_s
  rescue URI::InvalidURIError
    nil
  end

  def export_results
    File.open("seo_results.txt", "w", encoding: "UTF-8") do |file|
      @redis.keys("seo:*").each do |key|
        row = JSON.parse(@redis.get(key))

        file.puts "URL:                          #{row["url"]}"
        file.puts "Title:                        #{row["title"]}"
        file.puts "Title Length:                 #{row["title_length"]}"
        file.puts "Meta Description:             #{row["meta_description"]}"
        file.puts "Meta Description Length:      #{row["meta_description_length"]}"
        file.puts "H1:                           #{row["h1"]}"
        file.puts "H2:                           #{row["h2"]}"
        file.puts "H3:                           #{row["h3"]}"
        file.puts "Canonical:                    #{row["canonical"]}"
        file.puts "Robots Meta:                  #{row["robots_meta"]}"
        file.puts "Schema Present:               #{row["has_schema"]}"
        file.puts "Missing ALT %:                #{row["missing_alt_percentage"]}"
        file.puts "Word Count:                   #{row["word_count"]}"
        file.puts "Internal Links:               #{row["internal_links"]}"
        file.puts "External Links:               #{row["external_links"]}"
        file.puts "Broken Links:                 #{row["broken_links"]}"
        file.puts "Load Time:                    #{row["load_time"]}"
        file.puts "Page Size:                    #{row["page_size"]}"
        file.puts "HTTPS:                        #{row["is_https"]}"
        file.puts "Google Analytics Present:     #{row["has_google_analytics"]}"
        file.puts "Google Tag Manager Present:   #{row["has_google_tag_manager"]}"
        file.puts "-" * 70  # Adds a separator line for better readability
      end
    end
    puts "Results exported to seo_results.txt"
  end

  def run
    crawl(@start_url)
    @thread_pool.shutdown
    @thread_pool.wait_for_termination
    export_results
  end
end

# Run the crawler for Automation Test Store
crawler = UltimateSEOCrawler.new('https://automationteststore.com', 2, 10)
crawler.run
