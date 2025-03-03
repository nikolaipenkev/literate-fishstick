class SEOAnalyzer
  def initialize(url, page_data)
    @url = url
    @document = page_data[:document]
    @headers = page_data[:headers]
    @load_time = page_data[:load_time]
    @page_size = page_data[:page_size]
  end

  def analyze
    title = @document.at('title')&.text&.strip || "No Title"
    meta_desc = @document.at('meta[name="description"]')&.[]('content')&.strip || "No Meta Description"
    h1 = @document.at('h1')&.text&.strip || "No H1"
    h2 = @document.css('h2').map { |h| h.text.strip }.join(" | ")
    h3 = @document.css('h3').map { |h| h.text.strip }.join(" | ")
    canonical = @document.at('link[rel="canonical"]')&.[]('href') || @url
    robots_meta = @document.at('meta[name="robots"]')&.[]('content') || @headers["X-Robots-Tag"] || "No Robots Meta"
    schema_present = !@document.css('script[type="application/ld+json"]').empty?

    images = @document.css('img')
    missing_alt = images.count { |img| img['alt'].nil? || img['alt'].strip.empty? }
    alt_missing_percentage = images.empty? ? 0 : ((missing_alt.to_f / images.size) * 100).round(2)

    word_count = @document.text.split(/\s+/).size

    links = @document.css('a[href]').map { |a| a['href'] }
    internal_links = links.count { |l| l.start_with?('/') || l.include?(URI.parse(@url).host) }
    external_links = links.size - internal_links

    {
      url: @url,
      title: title,
      meta_description: meta_desc,
      h1: h1,
      h2: h2,
      h3: h3,
      canonical: canonical,
      robots_meta: robots_meta,
      schema_present: schema_present,
      missing_alt_percentage: "#{alt_missing_percentage}%",
      word_count: word_count,
      internal_links: internal_links,
      external_links: external_links,
      load_time: "#{@load_time}s",
      page_size: "#{@page_size} KB",
      is_https: @url.start_with?("https"),
      has_google_analytics: !!@document.at('script[src*="google-analytics.com"]'),
      has_google_tag_manager: !!@document.at('script[src*="googletagmanager.com"]')
    }
  end
end
