require 'nokogiri'
require 'httparty'
require 'uri'
require 'net/http'

class PageProcessor
  def initialize(url, cache)
    @url = url
    @cache = cache
  end

  def process_page
    puts "Processing: #{@url}"
    start_time = Time.now
    response = HTTParty.get(@url, follow_redirects: true, timeout: 10) rescue nil
    return unless response&.success?

    load_time = Time.now - start_time
    document = Nokogiri::HTML(response.body)
    save_seo_data(document, response.headers, load_time, response.body.bytesize)
  end

  def save_seo_data(document, headers, load_time, page_size)
    title = document.at('title')&.text&.strip || "No Title"
    meta_desc = document.at('meta[name="description"]')&.[]('content')&.strip || "No Meta Description"
    h1 = document.at('h1')&.text&.strip || "No H1"
    h2 = document.at('h2')&.text&.strip || "No H2"
    h3 = document.at('h3')&.text&.strip || "No H3"
    canonical = document.at('link[rel="canonical"]')&.[]('href') || @url
    robots_meta = document.at('meta[name="robots"]')&.[]('content') || headers["X-Robots-Tag"] || "No Robots Meta"
    images = document.css('img')
    missing_alt = images.count { |img| img['alt'].nil? || img['alt'].strip.empty? }
    total_images = images.size
    alt_missing_percentage = total_images.zero? ? 0 : ((missing_alt.to_f / total_images) * 100).round(2)
    word_count = document.text.split(/\s+/).size
    links = document.css('a[href]').map { |a| a['href'] }

    seo_data = {
      url: @url,
      title: title,
      meta_description: meta_desc,
      h1: h1,
      h2: h2,
      h3: h3,
      canonical: canonical,
      robots_meta: robots_meta,
      missing_alt_percentage: "#{alt_missing_percentage}%",
      word_count: word_count,
      internal_links: links.count { |l| l.include?(@url) },
      external_links: links.size - links.count { |l| l.include?(@url) },
      load_time: load_time,
      page_size: "#{(page_size / 1024.0).round(2)} KB",
    }

    @cache.save_seo_data(@url, seo_data)
  end

  def extract_links
    document = Nokogiri::HTML(HTTParty.get(@url).body)
    links = document.css('a[href]').map { |a| normalize_url(a['href']) }.compact.uniq
    links
  end

  def normalize_url(link)
    uri = URI.parse(link) rescue nil
    return nil unless uri
    uri.relative? ? URI.join(@url, uri).to_s : uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
