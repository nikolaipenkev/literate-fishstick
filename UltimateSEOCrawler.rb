require 'nokogiri'
require 'httparty'
require 'uri'
require 'sqlite3'
require 'json'
require 'concurrent-ruby'
require_relative 'database.rb'

class UltimateSEOCrawler
  def initialize(start_url, max_depth = 2, thread_pool_size = 10)
    @start_url = start_url
    @max_depth = max_depth
    @visited_urls = Concurrent::Hash.new # ✅ Thread-safe hash
    @thread_pool = Concurrent::FixedThreadPool.new(thread_pool_size) # ✅ Multi-threaded crawling
  end

  def crawl(url = @start_url, depth = 0)
    return if depth > @max_depth || already_crawled?(url) # ✅ Avoid revisits

    @visited_urls[url] = true # ✅ Mark URL as visited

    # ✅ Now running the whole process in the thread pool
    @thread_pool.post do
      process_page(url, depth)
    end
  end

  def process_page(url, depth)
    puts "Crawling: #{url}"
    start_time = Time.now
    response = fetch_page(url)
    return unless response

    load_time = Time.now - start_time
    document = Nokogiri::HTML(response.body)
    seo_data = extract_seo_data(document, url, response, load_time)

    save_to_database(seo_data)

    extract_links(document, url).each do |link|
      next if @visited_urls[link]

      @visited_urls[link] = true
      @thread_pool.post { crawl(link, depth + 1) }
    end
  end

  # ✅ Ensure all threads finish before exiting
  def wait_for_threads
    @thread_pool.shutdown
    @thread_pool.wait_for_termination
  end

  private

  def fetch_page(url)
    HTTParty.get(url, follow_redirects: true, timeout: 10) rescue nil
  end

  def extract_seo_data(document, url, response, load_time)
    {
      url: url,
      title: document.at('title')&.text&.strip || "No Title",
      title_length: (document.at('title')&.text&.strip || "").length,
      meta_description: document.at('meta[name="description"]')&.[]('content')&.strip || "No Meta Description",
      meta_description_length: (document.at('meta[name="description"]')&.[]('content')&.strip || "").length,
      h1: document.at('h1')&.text&.strip || "No H1",
      h2: document.css('h2').map { |h| h.text.strip }.join(" | "),
      h3: document.css('h3').map { |h| h.text.strip }.join(" | "),
      canonical: document.at('link[rel="canonical"]')&.[]('href') || url,
      robots_meta: document.at('meta[name="robots"]')&.[]('content') || response.headers["X-Robots-Tag"] || "No Robots Meta",
      schema_present: !document.css('script[type="application/ld+json"]').empty? ? 1 : 0,
      missing_alt_percentage: calculate_missing_alt(document),
      word_count: document.text.split(/\s+/).size,
      internal_links: count_internal_links(document, url),
      external_links: count_external_links(document, url),
      broken_links: count_broken_links(document),
      load_time: load_time.round(2),
      page_size: (response.body.bytesize / 1024.0).round(2),
      is_https: url.start_with?("https") ? 1 : 0,
      has_google_analytics: !document.at('script[src*="google-analytics.com"]').nil? ? 1 : 0,
      has_google_tag_manager: !document.at('script[src*="googletagmanager.com"]').nil? ? 1 : 0
    }
  end

  def already_crawled?(url)
    result = DB.execute("SELECT crawled FROM seo_data WHERE url = ?", [url]).first
    result && result["crawled"] == 1
  end

  def save_to_database(seo_data)
    DB.execute("INSERT INTO seo_data (
      url, title, title_length, meta_description, meta_description_length, h1, h2, h3,
      canonical, robots_meta, schema_present, missing_alt_percentage, word_count,
      internal_links, external_links, broken_links, load_time, page_size, is_https,
      has_google_analytics, has_google_tag_manager, crawled
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)  -- ✅ Set crawled = 1
    ON CONFLICT(url) DO UPDATE SET  -- ✅ If URL exists, update it
      title = excluded.title,
      title_length = excluded.title_length,
      meta_description = excluded.meta_description,
      meta_description_length = excluded.meta_description_length,
      h1 = excluded.h1,
      h2 = excluded.h2,
      h3 = excluded.h3,
      canonical = excluded.canonical,
      robots_meta = excluded.robots_meta,
      schema_present = excluded.schema_present,
      missing_alt_percentage = excluded.missing_alt_percentage,
      word_count = excluded.word_count,
      internal_links = excluded.internal_links,
      external_links = excluded.external_links,
      broken_links = excluded.broken_links,
      load_time = excluded.load_time,
      page_size = excluded.page_size,
      is_https = excluded.is_https,
      has_google_analytics = excluded.has_google_analytics,
      has_google_tag_manager = excluded.has_google_tag_manager,
      crawled = 1;  -- ✅ Always set to crawled
    ",
               [
                 seo_data[:url], seo_data[:title], seo_data[:title_length], seo_data[:meta_description],
                 seo_data[:meta_description_length], seo_data[:h1], seo_data[:h2], seo_data[:h3],
                 seo_data[:canonical], seo_data[:robots_meta],
                 seo_data[:schema_present], seo_data[:missing_alt_percentage], seo_data[:word_count],
                 seo_data[:internal_links], seo_data[:external_links], seo_data[:broken_links],
                 seo_data[:load_time], seo_data[:page_size], seo_data[:is_https],
                 seo_data[:has_google_analytics], seo_data[:has_google_tag_manager]
               ])
  end

  def calculate_missing_alt(document)
    images = document.css('img')
    missing_alt = images.count { |img| img['alt'].nil? || img['alt'].strip.empty? }
    total_images = images.size
    total_images.zero? ? 0 : ((missing_alt.to_f / total_images) * 100).round(2)
  end

  def count_internal_links(document, base_url)
    links = document.css('a[href]').map { |a| a['href'] }
    links.count { |l| l.start_with?('/') || l.include?(URI.parse(base_url).host) }
  end

  def count_external_links(document, base_url)
    links = document.css('a[href]').map { |a| a['href'] }
    links.count { |l| !l.start_with?('/') && !l.include?(URI.parse(base_url).host) }
  end

  def count_broken_links(document)
    document.css('a[href]').count { |a| link_broken?(a['href']) }
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
end