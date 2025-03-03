require 'concurrent'
require 'redis'
require_relative 'seo_page_processor'
require_relative 'seo_storage'

class SEOCrawler
  def initialize(start_url, max_depth = 2, thread_pool_size = 10)
    @start_url = start_url
    @max_depth = max_depth
    @visited_urls = Concurrent::Map.new
    @thread_pool = Concurrent::FixedThreadPool.new(thread_pool_size)
    @storage = SEOStorage.new
  end

  def crawl(url = @start_url, depth = 0)
    return if depth > @max_depth || @visited_urls.key?(url)

    @visited_urls[url] = true
    @thread_pool.post { process_page(url, depth) }
  end

  def process_page(url, depth)
    puts "Crawling: #{url}"
    page_data = SEOPageProcessor.new(url).fetch_page

    return unless page_data[:success]

    seo_data = SEOAnalyzer.new(url, page_data).analyze
    @storage.save_seo_data(seo_data)

    page_data[:links].each { |link| crawl(link, depth + 1) }
  end

  def run
    crawl(@start_url)
    @thread_pool.shutdown
    @thread_pool.wait_for_termination
    @storage.export_results
  end
end

crawler = SEOCrawler.new('https://automationteststore.com', 2, 10)
crawler.run
