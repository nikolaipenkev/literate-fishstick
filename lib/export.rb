require 'csv'

class Exporter
  def initialize(cache)
    @cache = cache
  end

  def export_results(format = :text)
    case format
    when :text
      export_to_text
    when :csv
      export_to_csv
    else
      puts "Unsupported format: #{format}"
    end
  end

  private

  def export_to_text
    File.open("seo_results.txt", "w", encoding: "UTF-8") do |file|
      @cache.all_seo_data.each do |entry|
        file.puts format_seo_data(entry[:seo_data])
        file.puts "-" * 70  # Adds a separator line for readability
      end
    end
    puts "Results exported to seo_results.txt"
  end

  def export_to_csv
    CSV.open("seo_results.csv", "wb", encoding: "UTF-8") do |csv|
      csv << header_columns  # Add the header row
      @cache.all_seo_data.each do |entry|
        csv << format_seo_data_for_csv(entry[:seo_data])  # Write data row
      end
    end
    puts "Results exported to seo_results.csv"
  end

  def header_columns
    [
      "URL", "Title", "Meta Description", "H1", "Canonical", "Robots Meta",
      "Missing ALT %", "Word Count", "Internal Links", "External Links",
      "Load Time", "Page Size", "Is HTTPS", "Google Analytics", "Google Tag Manager"
    ]
  end

  def format_seo_data(row)
    "URL:                          #{row['url']}\n" \
      "Title:                        #{row['title']}\n" \
      "Meta Description:             #{row['meta_description']}\n" \
      "H1:                           #{row['h1']}\n" \
      "Canonical:                    #{row['canonical']}\n" \
      "Robots Meta:                  #{row['robots_meta']}\n" \
      "Missing ALT %:                #{row['missing_alt_percentage']}\n" \
      "Word Count:                   #{row['word_count']}\n" \
      "Internal Links:               #{row['internal_links']}\n" \
      "External Links:               #{row['external_links']}\n" \
      "Load Time:                    #{row['load_time']}\n" \
      "Page Size:                    #{row['page_size']}\n" \
      "HTTPS:                        #{row['is_https']}\n" \
      "Google Analytics Present:     #{row['has_google_analytics']}\n" \
      "Google Tag Manager Present:   #{row['has_google_tag_manager']}"
  end

  def format_seo_data_for_csv(row)
    [
      row['url'], row['title'], row['meta_description'], row['h1'], row['canonical'],
      row['robots_meta'], row['missing_alt_percentage'], row['word_count'], row['internal_links'],
      row['external_links'], row['load_time'], row['page_size'], row['is_https'],
      row['has_google_analytics'], row['has_google_tag_manager']
    ]
  end
end
