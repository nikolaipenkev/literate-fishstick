require 'nokogiri'
require 'httparty'
require 'uri'
require 'concurrent'
require 'redis'
require 'json'
require 'csv'
require 'net/http'
require_relative 'page_processor'
require_relative 'cache'
require_relative 'export'

class Crawler
  def initialize(start_url, max_depth = 2, thread_pool_size = 10)
    @start_url = start_url
    @max_depth = max_depth
    @cache = Cache.new
    @thread_pool = Concurrent::FixedThreadPool.new(thread_pool_size)
  end

  def crawl(url = @start_url, depth = 0)
    return if depth > @max_depth || @cache.exists?(url)

    @cache.mark_as_crawled(url)
    @thread_pool.post { process_page(url, depth) }
  end

  def process_page(url, depth)
    page_processor = PageProcessor.new(url, @cache)
    page_processor.process_page
    extract_links(url, depth).each { |link| crawl(link, depth + 1) }
  end

  def extract_links(url, depth)
    page_processor = PageProcessor.new(url, @cache)
    page_processor.extract_links
  end

  def run
    crawl(@start_url)
    @thread_pool.shutdown
    @thread_pool.wait_for_termination
    exporter = Exporter.new(@cache)
    exporter.export_results
  end
end
