require 'nokogiri'
require 'httparty'
require 'uri'

class SEOPageProcessor
  def initialize(url)
    @url = url
  end

  def fetch_page
    start_time = Time.now
    response = HTTParty.get(@url, follow_redirects: true, timeout: 10) rescue nil
    return { success: false } unless response&.success?

    document = Nokogiri::HTML(response.body)
    {
      success: true,
      document: document,
      headers: response.headers,
      load_time: (Time.now - start_time).round(2),
      page_size: (response.body.bytesize / 1024.0).round(2),
      links: extract_links(document)
    }
  end

  private

  def extract_links(document)
    document.css('a[href]').map { |a| normalize_url(a['href']) }.compact.uniq
  end

  def normalize_url(link)
    return nil unless link
    uri = URI.parse(link) rescue nil
    return nil unless uri
    uri.relative? ? URI.join(@url, uri).to_s : uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
